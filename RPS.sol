// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract RPS {
    uint public numPlayer = 0;
    uint public reward = 0;
    mapping(address => bytes32) public player_commit;
    mapping(address => bool) public player_revealed;
    address[] public players;
    
    uint public revealDeadline;
    CommitReveal public commitReveal;
    TimeUnit public timeUnit;
    
    constructor(address _commitReveal, address _timeUnit) {
        commitReveal = CommitReveal(_commitReveal);
        timeUnit = TimeUnit(_timeUnit);
    }

    function addPlayer() public payable {
        require(numPlayer < 2);
        if (numPlayer > 0) {
            require(msg.sender != players[0]);
        }
        require(msg.value == 0.000001 ether);
        reward += msg.value;
        players.push(msg.sender);
        numPlayer++;
    }

    function reveal(bytes32 choice) public {
        require(numPlayer == 2, "Not enough players");
        require(!player_revealed[msg.sender], "Already revealed");
        require(commitReveal.getHash(choice) == player_commit[msg.sender], "Invalid reveal");
        
        player_revealed[msg.sender] = true;
        commitReveal.reveal(choice);
        
        if (player_revealed[players[0]] && player_revealed[players[1]]) {
            _checkWinnerAndPay();
        }
    }

    function _checkWinnerAndPay() private {
        uint p0Choice = uint(uint256(commitReveal.getHash(keccak256(abi.encodePacked(players[0])))) % 3);
        uint p1Choice = uint(uint256(commitReveal.getHash(keccak256(abi.encodePacked(players[1])))) % 3);
        address payable account0 = payable(players[0]);
        address payable account1 = payable(players[1]);
        
        if ((p0Choice + 1) % 3 == p1Choice) {
            account1.transfer(reward);
        } else if ((p1Choice + 1) % 3 == p0Choice) {
            account0.transfer(reward);    
        } else {
            account0.transfer(reward / 2);
            account1.transfer(reward / 2);
        }
    }
    
    function claimTimeout() public {
        require(timeUnit.elapsedSeconds() > 300, "Time not expired");
        
        if (player_revealed[players[0]] && !player_revealed[players[1]]) {
            payable(players[0]).transfer(reward);
        } else if (!player_revealed[players[0]] && player_revealed[players[1]]) {
            payable(players[1]).transfer(reward);
        } else {
            payable(msg.sender).transfer(reward);
        }
    }
}

contract CommitReveal {
    function getHash(bytes32 data) public pure returns(bytes32) {
        return keccak256(abi.encodePacked(data));
    }
    function reveal(bytes32 revealHash) public {}
}

contract TimeUnit {
    uint256 public startTime;
    function setStartTime() public { startTime = block.timestamp; }
    function elapsedSeconds() public view returns (uint256) { return (block.timestamp - startTime); }
}
