pragma solidity ^0.4.18;

contract RockPaperScissors {
	// Storage variables

	// Addresses of both players.
	address addr1;
	address addr2;

	/* Blockchain is public and thus everyone can see the data stored.
	Storing player's move as a hash prevents the adversary to see the opponents move
	and play the winning move.
	*/
	bytes32 hashed_move1;
	bytes32 hashed_move2;
	// Moves for players 1 and 2. Populated only after the reveal stage.
	bytes32 move1;
	bytes32 move2;
	// Fixed reward is 10 million wei. Yeap. It's a lot.
	uint reward = 10000000;
	uint claim_timer;

	mapping (bytes32 => mapping (bytes32 => uint8)) game_verdict;

	// Initialise contract. Initialize gaming scenarios.
	function RockPaperScissors() public {
		// 0 undefined - invalid move
		// 1 player 2 won
		// 2 tie
		// 3 player 1 won
		game_verdict["rock"]["paper"] = 1;
		game_verdict["rock"]["scissors"] = 3;
		game_verdict["rock"]["rock"] = 2;
		game_verdict["paper"]["paper"] = 2;
		game_verdict["paper"]["rock"] = 3;
		game_verdict["paper"]["scissors"] = 1;
		game_verdict["scissors"]["paper"] = 3;
		game_verdict["scissors"]["rock"] = 1;
		game_verdict["scissors"]["scissors"] = 2;
	}

	// The player provides a hash_move. The game fee is also paid.
	function move(bytes32 hash_move) public payable {
		require (msg.value > reward);

		// Send remaining value back to the address that called this function.
		msg.sender.transfer(msg.value - reward);

		if (addr1 != 0) {
			addr2 = msg.sender;
			hashed_move2 = hash_move;
		} else {
			addr1 = msg.sender;
			hashed_move1 = hash_move;
		}
	}

	// Require that both players have made their move.
	function reveal_move(bytes32 p_move, bytes32 h_key) public {

		if (sha256(p_move, h_key) == hashed_move1) {
			move1 = p_move;
			claim_timer = now + 86400; // one day is seconds.
		}
		if (sha256(p_move, h_key) == hashed_move2) {
			move2 = p_move;
			claim_timer = now + 86400;
		}

		// In the cases below we prevent someone calling the claim_reward
		// by setting claim_timer to zero.

		// Player 2 reveals, but player 1 hasn't made their move.
		if (hashed_move1 == 0 && move2 != 0) {
			claim_timer = 0;
			addr2.transfer(this.balance);
		}
		// Player 1 reveals, but player 1 hasn't made their move.
		if (hashed_move2 == 0 && move1 != 0) {
			claim_timer = 0;
			addr1.transfer(this.balance);
		}
		// Both players played. Determine the winner.
		if (move1 != 0 && move2 != 0) {
			claim_timer = 0;
			determine_winner(game_verdict[move1][move2]);
		}
	}

	// Claims reward in the case one of the players does not reveal
	// their move in time. We expect this to happen many times since
	// in the case where the revealer is winner the loser has no 
	// reason to reveal their move and spend gas for the transaction.
	function claim_reward() public {
		require (claim_timer > now);
		require (msg.sender == addr1 || msg.sender == addr2);

		if (move1 != 0) {
			addr1.transfer(2*reward);
		} else {
			addr2.transfer(2*reward);
		}
	}

	function determine_winner(uint8 result) internal {
		if (result == 0 || result == 2) {
			addr1.transfer(reward);
			addr1.transfer(reward);
		} else if (result == 1) {
			addr2.transfer(2*reward);
		} else {
			addr1.transfer(2*reward);
		}
	}
}