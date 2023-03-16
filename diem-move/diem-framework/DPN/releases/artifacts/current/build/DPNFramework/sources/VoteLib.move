///////////////////////////////////////////////////////////////////////////
// 0L Module
// VoteLib
// Intatiate different types of user interactive voting
///////////////////////////////////////////////////////////////////////////

// TODO: Move this to a separate address. Potentially has separate governance.
address DiemFramework { 

  module ParticipationVote {

    // ParticipationVote is a single issue referendum, with only votes in favor or against.
    // The design of the policies attempts to accomodate online voting where votes tend to happen:
    // 1. publicly
    // 2. asynchronously
    // 3. with a low turnout
    // 4. of voters with high conviction

    // Low turnouts are not indicative of disinterest (often termed voter apathy), but instead it is just "rational ignorance" of the matters being voted. Adaptive deadlines and thresholds are an attempt to encourage more familiarity with the matters, and thus more participation. At the same time it allows for consensus decisions to be reached in a timely manner by the active and interested participants.

    // The ballots have dynamic deadlines and thresholds.
    // deadlines can be extended by dissenting votes from the current majority vote. This cannot be done indefinitely, as the extension is capped by the max_deadline.
    // The threshold (percent approval/rejection which needs to be met) is determined post-hoc. Referenda are expensive, for communities, leaders, and voters. Instead of scapping a vote which doesn't achieve a pre-established number of participants (quorum), the vote is allowed to be tallied and be seen as valid. However, the threshold must be higher (more than 51%) in cases where the turnout is low. In blockchain polkadot network has prior art for this: https://wiki.polkadot.network/docs/en/learn-governance#adaptive-quorum-biasing
    // In Polkadot implementation there are positive and negative biasing. Negative biasing (when turnout is low, a lower amount of votes is needed) seems to be an edge case.

    // Regarding deadlines. The problem with adaptive thresholds is that it favors the engaged community. If you are unaware of the process, or if the process ocurred silently, it's very challenging to swing the vote. So the minority vote may be disadvantaged due to lack of engagement, and there should be some accomodation. If they are coming late to the vote, AND in significant numbers, then they can get an extension. The initial design aims to allow an extension if on the day the poll closes, a sufficient amount of the vote was shifted in the minority direction, an extra day is added. This will happen for each new deadline.

    // THE BALLOT
    // Ballot is a single proposal that can be voted on.
    // Each ballot will run for the minimum period of time.
    // The deadline can be extended with dissenting votes from the current majority vote.
    // The turnout can be extended with dissenting votes from the current majority vote.
    // the threshold is dictated by the turnout. In this implementation the curve is fixed, and linear.
    // At 1/8th turnout, the threshold to be met is 100%
    // At 7/8th turnout, the threshold to be met is 51%

    use Std::FixedPoint32;
    use Std::Vector;
    use Std::Signer;
    use Std::GUID::{Self, GUID, ID};
    use DiemFramework::DiemConfig;
    use Std::Errors;

    const ECOMPLETED: u64 = 300010;

    // TODO: These may be variable on a per project basis. And these
    // should just be defaults.
    const PCT_SCALE: u64 = 10000;
    const LOW_TURNOUT: u64 = 1250;// 12.5% turnout
    const HIGH_TURNOUT: u64 = 8750;// 87.5% turnout
    const LOW_THRESH: u64 = 10000;// 100% pass at low turnout
    const HIGH_THRESH: u64 = 5100;// 51% pass at high turnout
    const MINORITY_EXT_MARGIN: u64 = 500; // The change in vote gap between majority and minority must have changed in the last day by this amount to for the minority to get an extension.

    // Any user account can create an election.
    // usually a smart contract will be the one to create the election 
    // connected to some contract logic.
    // The contract may have multiple ballots at a given time.
    // Historical completed ballots are also stored in a separate vector.

    struct Ballot has key, store { // Note, this is a hot potato. Any methods chaning it must return the struct to caller.
      guid: GUID,
      name: vector<u8>, // TODO: change to ascii string
      cfg_deadline: u64, // original deadline, which may be extended. Note dedaline is at the END of this epoch (cfg_deadline + 1 stops taking votes)
      cfg_max_extensions: u64, // if 0 then no max. Election can run until threshold is met.
      cfg_min_turnout: u64,
      cfg_minority_extension: bool,
      completed: bool,
      max_votes: u64, // what's the entire universe of votes. i.e. 100% turnout
      // vote_tickets: VoteTicket, // the tickets that can be used to vote, which will be deducted as votes are cast. It is initialized with the max_votes.
      // Note the developer needs to be aware that if the right to vote changes throughout the period of the election (more coins, participants etc) then the max_votes and tickets could skew from expected results. Vote tickets can be distributed in advance.
      votes_approve: u64, // the running tally of approving votes,
      votes_reject: u64, // the running tally of rejecting votes,
      epoch_extended: u64, // which epoch was the deadline extended to
      last_epoch_voted: u64, // the last epoch which received a vote
      last_epoch_approve: u64, // what was the approval percentage at the last epoch. For purposes of calculating extensions.
      last_epoch_reject: u64, // what was the rejection percentage at the last epoch. For purposes of calculating extensions.
      tally_approve: u64,  // use two decimal places 1234 = 12.34%
      tally_turnout: u64, // use two decimal places 1234 = 12.34%
      tally_pass: bool, // if it passed, for archival purposes
    }

    struct VoteReceipt has key, store, drop, copy { 
      guid: GUID::ID,
      approve_reject: bool,
      weight: u64,
    }
    struct IVoted has key {
      elections: vector<VoteReceipt>,
    }

    public fun new(
      sig: &signer,
      name: vector<u8>,
      deadline: u64,
      max_extensions: u64,
    ): Ballot {
        Ballot {
          guid: GUID::create(sig),
          name: name,
          cfg_deadline: deadline,
          cfg_max_extensions: max_extensions, // 0 means infinite extensions
          cfg_min_turnout: 1250,
          cfg_minority_extension: true,
          completed: false,
          max_votes: 0,
          votes_approve: 0,
          votes_reject: 0,
          epoch_extended: 0,
          last_epoch_voted: 0,
          last_epoch_approve: 0,
          last_epoch_reject: 0,
          tally_approve: 0,
          tally_turnout: 0,
          tally_pass: false,
        }
    }

    // Only the contract, which is the keeper of the Ballot, can allow a user to temporarily hold the Ballot struct to update the vote. The user cannot arbiltrarily update the vote, with an arbitrary number of votes.
    // This is a hot potato, it cannot be dropped.

    public fun vote(ballot: &mut Ballot, user: &signer, approve_reject: bool, weight: u64) acquires IVoted {
      assert!(check_expired(ballot), Errors::invalid_state(ECOMPLETED));

      // check if this person voted already.
      // If the vote is the same directionally (approve, reject), exit early.
      // otherwise, need to subtract the old vote and add the new vote.
      let user_addr = Signer::address_of(user);
      let (idx, is_found) = find_prior_vote_idx(user_addr, &GUID::id(&ballot.guid));

      if (is_found) {
        let vote = get_vote_receipt(user_addr, idx);
        if (vote.approve_reject != approve_reject) {
          // subtract the old vote
          if (approve_reject) {
            // if the new vote is approval, remove old votes from rejected
            ballot.votes_reject = ballot.votes_reject - vote.weight;
          } else {
            // the new vote is a rejection, 
            ballot.votes_approve = ballot.votes_approve - vote.weight;
          };
        }
      };

      // if we are in a new epoch than the previous last voter, then store that epoch data.
      let epoch_now = DiemConfig::get_current_epoch();
      if (epoch_now > ballot.last_epoch_voted) {
        ballot.last_epoch_approve = ballot.votes_approve;
        ballot.last_epoch_reject = ballot.votes_reject;
      };


      // in every case, add the new vote
      ballot.last_epoch_voted = epoch_now;
      if (approve_reject) {
        ballot.votes_approve = ballot.votes_approve + weight;
      } else {
        ballot.votes_reject = ballot.votes_reject + weight;
      };

      // if this is a divergent vote, we give it the opportunity to extend the vote, to get more participation.
      maybe_extend(ballot);

      // always tally on each vote
      // make sure all extensions happened in previous step.
      maybe_tally(ballot);

      // this will handle the case of updating the receipt in case this is a second vote.
      make_receipt(user, &GUID::id(&ballot.guid), approve_reject, weight);
    }

    fun check_expired(ballot: &mut Ballot): bool {
      let epoch = DiemConfig::get_current_epoch();

      // if completed, stop tally
      if (ballot.completed) { return true }; // this should be checked above anyways.

      // this may be a vote that never expires, until a decision is reached
      if (ballot.cfg_max_extensions == 0 ) { return false };

      // if original and extended deadline have passed, stop tally
      if (
        epoch > ballot.cfg_deadline &&
        epoch > ballot.epoch_extended
      ) { 
        ballot.completed = true;
        return true
      };

      false
    }

    // we may need to extend the ballot if on the last day (TBD a wider window) the vote had a big shift in favor of the minority vote.
    fun maybe_extend(ballot: &mut Ballot) {

      let epoch = DiemConfig::get_current_epoch();

      // Are we on the last day of voting (extension window)?
      // if not, return early.
      if (ballot.cfg_deadline == epoch) { return };

      // did we already extend today?
      if (ballot.epoch_extended > epoch) { return };

      // do nothing is the votes are even (or more likely, uninitialized at 0);
      if (ballot.votes_approve == ballot.votes_reject) { return };

      // Who was ahead in the previous epoch?
      let (prev_lead, prev_trail, prev_lead_updated, prev_trail_updated) = if (ballot.last_epoch_approve > ballot.last_epoch_reject) {
        // if the "approve" vote WAS leading.
        (ballot.last_epoch_approve, ballot.last_epoch_reject, ballot.votes_approve, ballot.votes_reject)
        
      } else {
        (ballot.last_epoch_reject, ballot.last_epoch_approve, ballot.votes_reject, ballot.votes_approve)
      };

      // approvals are winning

      let prior_margin = ((prev_lead - prev_trail) * PCT_SCALE)/ (prev_lead + prev_trail);

      // the current margin may have flipped, so we need to check the direction of the vote.
      // if so then give an automatic extensions
      if (prev_lead_updated < prev_trail_updated) {
        ballot.epoch_extended = ballot.epoch_extended + 1;
        return
      } else {
        let current_margin = (prev_lead_updated - prev_trail_updated) * PCT_SCALE / (prev_lead_updated + prev_trail_updated);

        if (current_margin - prior_margin > MINORITY_EXT_MARGIN) {
          ballot.epoch_extended = ballot.epoch_extended + 1;
          return
        }
      }
    }

    fun maybe_tally(ballot: &mut Ballot) {
      // stop tallying if the expiration is passed or the threshold has been met.
      if (check_expired(ballot)) { return };
      

      let total_votes = ballot.votes_approve + ballot.votes_reject;
      // figure out the turnout
      let m = FixedPoint32::create_from_rational(total_votes, ballot.max_votes);

      ballot.tally_turnout = FixedPoint32::multiply_u64(PCT_SCALE, m); // scale up

      // calculate the dynamic threshold needed.
      let t = get_threshold_from_turnout(total_votes, ballot.max_votes);
      // check the threshold that needs to be met met turnout
      ballot.tally_approve = FixedPoint32::multiply_u64(PCT_SCALE, FixedPoint32::create_from_rational(ballot.votes_approve, total_votes));

      // the first vote which crosses the threshold causes the poll to end.
      if (ballot.tally_approve > t) {
        ballot.completed = true;
        // before marking it pass, make sure the minimum quorum was met
        // by default 12.50%
        if (ballot.tally_turnout > ballot.cfg_min_turnout) {
          ballot.tally_pass = true;
        }
      }
    }

    // TODO: this should probably use Decimal.move
    // can't multiply FixedPoint32 types directly.
    fun get_threshold_from_turnout(voters: u64, max_votes: u64): u64 {
      // let's just do a line
      // y = mx + b
      let turnout = FixedPoint32::create_from_rational(voters, max_votes);
      let x = FixedPoint32::multiply_u64(PCT_SCALE, turnout); // scale to two decimal points.

      let m = FixedPoint32::create_from_rational((HIGH_THRESH - LOW_THRESH), (HIGH_TURNOUT - LOW_TURNOUT));
      let b = LOW_THRESH - FixedPoint32::multiply_u64(LOW_TURNOUT, *&m);
      
      let y = FixedPoint32::multiply_u64(x, m) + b;

      y
    }

    fun make_receipt(user_sig: &signer, vote_id: &ID, approve_reject: bool, weight: u64) acquires IVoted {

      let user_addr = Signer::address_of(user_sig);

      let receipt = VoteReceipt {
        guid: *vote_id,
        approve_reject: approve_reject,
        weight: weight,
      };

      if (!exists<IVoted>(user_addr)) {
        let ivoted = IVoted {
          elections: Vector::empty(),
        };
        move_to<IVoted>(user_sig, ivoted);
      };

      let (idx, is_found) = find_prior_vote_idx(user_addr, vote_id);

      let ivoted = borrow_global_mut<IVoted>(user_addr);
      if (is_found) {
        Vector::remove(&mut ivoted.elections, idx);
      };
      Vector::push_back(&mut ivoted.elections, receipt);
    }

    fun find_prior_vote_idx(user_addr: address, vote_id: &ID): (u64, bool) acquires IVoted {
      if (!exists<IVoted>(user_addr)) {
        return (0, false)
      };
      
      let ivoted = borrow_global<IVoted>(user_addr);
      let len = Vector::length(&ivoted.elections);
      let i = 0;
      while (i < len) {
        let receipt = Vector::borrow(&ivoted.elections, i);
        if (&receipt.guid == vote_id) {
          return (i, true)
        };
        i = i + 1;
      };

      return (0, false)
    }

    fun get_vote_receipt(user_addr: address, idx: u64): VoteReceipt acquires IVoted {
      let ivoted = borrow_global<IVoted>(user_addr);
      let r = Vector::borrow(&ivoted.elections, idx);
      return *r
    }

    //////// GETTERS ////////
    /// get the ballot id
    public fun get_ballot_id(ballot: &Ballot): ID {
      return GUID::id(&ballot.guid)
    }

    /// gets the receipt data
    // should return an OPTION.
    public fun get_receipt_data(user_addr: address, vote_id: &ID): (bool, u64) acquires IVoted {
      let (idx, found) = find_prior_vote_idx(user_addr, vote_id);
      if (found) {
          let v = get_vote_receipt(user_addr, idx);
          return (v.approve_reject, v.weight)
        };
      return (false, 0)
    } 

  }

  // // TODO: Fix publishing on test harness.
  // // see test _meta_import_vote.move
  // // There's an issue with the test harness, where it cannot publish the module
  // // task 2 'run'. lines 31-51:
  // // Error: error[E03002]: unbound module
  // // /var/folders/0s/7kz0td0j5pqffbc143hq52bm0000gn/T/.tmp3EAMzm:3:9
  // // 
  // //      use 0x1::GUID;
  // //          ^^^^^^^^^ Invalid 'use'. Unbound module: '0x1::GUID'

  module DummyTestVote {

    use DiemFramework::ParticipationVote::{Self, Ballot};
    use Std::GUID;
    use DiemFramework::Testnet;

    struct Vote has key {
      ballot: Ballot,
    }

    // initialize this data on the address of the election contract
    public fun init(
      sig: &signer,
      deadline: u64,
      name: vector<u8>,
      max_extensions: u64,
      
    ): GUID::ID {
      assert!(Testnet::is_testnet(), 0);
      let ballot = ParticipationVote::new(sig, name, deadline, max_extensions);

      let id = ParticipationVote::get_ballot_id(&ballot);
      move_to(sig, Vote { ballot });
      id
    }

    public fun vote(sig: &signer, election_addr: address, weight: u64, approve_reject: bool) acquires Vote {
      assert!(Testnet::is_testnet(), 0);
      let vote = borrow_global_mut<Vote>(election_addr);
      ParticipationVote::vote(&mut vote.ballot, sig, approve_reject, weight);
    }

    public fun get_id(election_addr: address): GUID::ID acquires Vote {
      assert!(Testnet::is_testnet(), 0);
      let vote = borrow_global_mut<Vote>(election_addr);
      ParticipationVote::get_ballot_id(&vote.ballot)
    }
  }
}