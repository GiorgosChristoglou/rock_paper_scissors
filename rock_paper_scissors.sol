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
	string move1;
	string move2;
	// Fixed reward is 10 million wei. Yeap. It's a lot.
	uint reward = 10000000;
	uint claim_timer;
	bool revealed_move;
	mapping (string => mapping (string => uint8)) game_verdict;

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
		require (!revealed_move);
		require (msg.value >= reward);
		require (hash_move != 0);

		if (addr1 != 0 && addr1 != msg.sender) {
			msg.sender.transfer(msg.value - reward);
			addr2 = msg.sender;
			hashed_move2 = hash_move;
		} else {
			msg.sender.transfer(msg.value - reward);
			addr1 = msg.sender;
			hashed_move1 = hash_move;
		}
	}

	// Player 1 regrets playing or second player hasn't made their move.
	function get_refund() public {
		if (hashed_move1 != 0 && hashed_move2 == 0
			&& addr1 == msg.sender) {
			addr1.transfer(reward);
		}
	}

	// Require that both players have made their move.
	// Returns true if the reveal was successful.
	function reveal_move(string p_move, string h_key) public returns(bool, uint) {
		bool valid_reveal = false;
		bytes32 sha_hash = sha256(p_move, h_key);
		if (sha_hash == hashed_move1) {
			valid_reveal = true;
			move1 = p_move;
			claim_timer = now + 1; // one day in seconds.
		}
		if (sha_hash == hashed_move2) {
			valid_reveal = true;
			move2 = p_move;
			claim_timer = now + 1;
		}

		if (!strempty(move1) && !strempty(move2)) {
			claim_timer = 0;
			determine_winner(game_verdict[move1][move2]);
		}

		if (valid_reveal) revealed_move = true;

		return (valid_reveal, claim_timer);
	}

	// Claims reward in the case one of the players does not reveal
	// their move in time. We expect this to happen many times since
	// in the case where the revealer is winner the loser has no 
	// reason to reveal their move and spend gas for the transaction.
	function claim_reward() public returns(bool) {
		require (claim_timer < now);

		if (strempty(move1)) {
			addr2.transfer(2*reward);
			restartgame();
			return true;
		} else {
			addr2.transfer(2*reward);
			restartgame();
			return true;
		}

		return false;
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
		restartgame();
	}

	function strempty(string str) internal pure returns(bool) {
		bytes memory bytes_str = bytes(str);
		return bytes_str.length == 0;
	}

	function restartgame() internal {
		addr1 = 0;
		addr2 = 0;
		move1 = "";
		move2 = "";
		hashed_move1 = bytes32(0);
		hashed_move2 = bytes32(0);
		claim_timer = 0;
		revealed_move = false;
	}
}
