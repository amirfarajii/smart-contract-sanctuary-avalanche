//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IDaiContract {
  function balanceOf(address, uint256) external view returns (uint256);
}
contract BridgeDao {
    
    address public owner;
    uint256 nextProposal;
    uint256[] validTokens;
    IDaiContract bridgesDaoContract;

    constructor(){
      owner = msg.sender;
      nextProposal = 1;
      bridgesDaoContract = IDaiContract(0x153D2E6FD6Ff14892b75b3Cdd8161153a91ec41E);
      validTokens = [1];
    }

    struct proposal{
      uint256 id;
      bool exists;
      string description;
      uint deadline;
      uint256 voteFor;
      uint256 voteAgainst;
      address[] canVote;
      uint256 maxVotes;
      mapping(address => bool) voteStatus;
      bool countConducted;
      bool passed;
    }

    mapping(uint256 => proposal) public Proposals;

    event ProposalCreated(
      uint256 id,
      string description,
      uint256 maxVotes,
      address proposer
    );

    event newVote(
      uint256 votesFor,
      uint256 votesAgainst,
      address voter,
      uint256 proposal,
      bool votedFor
    );

    event proposalCount(
      uint256 id,
      bool passed
    );

    function isUserProposalEligible(address _proposalist) private view returns (bool){
      for(uint i = 0; i < validTokens.length; i++){
        if(bridgesDaoContract.balanceOf(_proposalist, validTokens[i]) >= 1){
          return true;
        }
      }
      return false;
    }

    function isVoterEligible(uint256 _id, address _voter) private view returns (bool){
      for(uint256 i = 0; i < Proposals[i].canVote.length; i++){
        if(Proposals[_id].canVote[i] == _voter){
          return true;
        }
      }
      return false;
    }

    function createProposal(string memory _description, address[] memory _canVote) public {
      require(isUserProposalEligible(msg.sender), "Not Allowed, must hold SNFT!");

      proposal storage newProposal = Proposals[nextProposal];
      newProposal.id = nextProposal;
      newProposal.exists = true;
      newProposal.description = _description;
      newProposal.deadline = block.number + 100;
      newProposal.canVote = _canVote;
      newProposal.maxVotes = _canVote.length;

      emit ProposalCreated(newProposal.id, newProposal.description, newProposal.maxVotes, msg.sender);
      nextProposal++;
    }

    function vote(uint256 _id, bool _vote) public {
      require(Proposals[_id].exists, "Does not exist");
      require(isVoterEligible(_id, msg.sender), "You are not allowed to vote!");
      require(!Proposals[_id].voteStatus[msg.sender], "Already Voted!");
      require(block.number <= Proposals[_id].deadline, "Deadline has passed, can no longer vote!");

      proposal storage p = Proposals[_id];

      if(_vote) {
        p.voteFor++;
      }else{
        p.voteAgainst++;
      }

      p.voteStatus[msg.sender] = true;

      emit newVote(p.voteFor, p.voteAgainst, msg.sender, _id, _vote);
    }

    function countVotes(uint256 _id ) public {
      require(msg.sender == owner, "Only owner");
      require(Proposals[_id].exists, "Does not exist");
      require(block.number > Proposals[_id].deadline, "Voting is still ongoing");      
      require(!Proposals[_id].countConducted, "Already COunted!");

       proposal storage p = Proposals[_id];

      if(Proposals[_id].voteAgainst < Proposals[_id].voteFor) {
        p.passed = true;
      }

      p.countConducted = true;

      emit proposalCount(_id, p.passed);
      
    }

    function addToken(uint256 _tokenId) public{
      require(msg.sender == owner, "Only Owner");

      validTokens.push(_tokenId);
    }
}