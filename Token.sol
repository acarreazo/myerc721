pragma solidity ^0.5.10;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./ERC165.sol";
import "./SafeMath.sol";

contract Token is IERC721, ERC165, SafeMath {
  
    uint constant dnaDigits = 10;
    uint constant dnaModulus = 10 ** dnaDigits;

    // Equals to `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
    // which can be also obtained as `IERC721Receiver(0).onERC721Received.selector`
    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;

    struct Token {
        string name;
        uint dna;
    }

    Token[] public tokens;

    // Mapping from owner to id of Token
    mapping (uint => address) public tokenToOwner;

    // Mapping from owner to number of owned token
    mapping (address => uint) public ownerTokenCount;

    // Mapping from token ID to approved address
    mapping (uint => address) tokenApprovals;

    // Mapping from owner to operator approvals
    mapping (address => mapping (address => bool)) private operatorApprovals;

    // Create random Token from string (name) and DNA
    function _createToken(string memory _name, uint _dna)
        internal
        isUnique(_name, _dna)
    {
        // Add Token to array and get id
        uint id = safeSub(tokens.push(Token(_name, _dna)), 1);
        // Map owner to id of Token
        assert(tokenToOwner[id] == address(0));
        tokenToOwner[id] = msg.sender;
        ownerTokenCount[msg.sender] = safeAdd(ownerTokenCount[msg.sender], 1);
    }

    // Creates random Token from string (name)
    function createRandomToken(string memory _name)
        public
    {
        uint randDna = generateRandomDna(_name, msg.sender);
        _createToken(_name, randDna);
    }

    // Generate random DNA from string (name) and address of the owner (creator)
    function generateRandomDna(string memory _str, address _owner)
        public
        pure
        returns(uint)
    {
        // Generate random uint from string (name) + address (owner)
        uint rand = uint(keccak256(abi.encodePacked(_str))) + uint(_owner);
        rand = rand % dnaModulus;
        return rand;
    }

    // Returns array of Tokens found by owner
    function getTokensByOwner(address _owner)
        public
        view
        returns(uint[] memory)
    {
        uint[] memory result = new uint[](ownerTokenCount[_owner]);
        uint counter = 0;
        for (uint i = 0; i < tokens.length; i++) {
            if (tokenToOwner[i] == _owner) {
                result[counter] = i;
                counter++;
            }
        }
        return result;
    }

    // Transfer Token to other wallet (internal function)
    function transferFrom(address _from, address _to, uint256 _tokenId)
        external
    {
        require(_from != address(0) && _to != address(0));
        require(_exists(_tokenId));
        require(_from != _to);
        require(_isApprovedOrOwner(msg.sender, _tokenId));
        ownerTokenCount[_to] = safeAdd(ownerTokenCount[_to], 1);
        ownerTokenCount[_from] = safeSub(ownerTokenCount[_from], 1);
        tokenToOwner[_tokenId] = _to;
        emit Transfer(_from, _to, _tokenId);
        _clearApproval(_to, _tokenId);
    }

    /**
     * Safely transfers the ownership of a given token ID to another address
     * If the target address is a contract, it must implement `onERC721Received`,
     * which is called upon a safe transfer, and return the magic value
     * `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`; otherwise,
     * the transfer is reverted.
    */
    function safeTransferFrom(address from, address to, uint256 tokenId)
        public
    {
        // solium-disable-next-line arg-overflow
        this.safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * Safely transfers the ownership of a given token ID to another address
     * If the target address is a contract, it must implement `onERC721Received`,
     * which is called upon a safe transfer, and return the magic value
     * `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`; otherwise,
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data)
        public
    {
        this.transferFrom(from, to, tokenId);
        // solium-disable-next-line arg-overflow
        require(_checkOnERC721Received(from, to, tokenId, _data));
    }

    /**
     * Internal function to invoke `onERC721Received` on a target address
     * The call is not executed if the target address is not a contract
     */
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data)
        internal
        returns(bool)
    {
        if (!isContract(to)) {
            return true;
        }

        bytes4 retval = IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, _data);
        return (retval == _ERC721_RECEIVED);
    }

    // Burn Token - destroys Token completely
    function burn(uint256 _tokenId)
        external
    {
        address _from = msg.sender;
        require(_from != address(0));
        require(_exists(_tokenId));
        require(_isApprovedOrOwner(msg.sender, _tokenId));
        ownerTokenCount[_from] = safeSub(ownerTokenCount[_from], 1);
        tokenToOwner[_tokenId] = address(0);
    }

    // Returns count of Tokens by address
    function balanceOf(address _owner)
        external
        view
        returns(uint256 _balance)
    {
        return ownerTokenCount[_owner];
    }

    // Returns owner of the Token found by id
    function ownerOf(uint256 _tokenId)
        external
        view
        returns(address _owner)
    {
        address owner = tokenToOwner[_tokenId];
        require(owner != address(0));
        return owner;
    }
	


    // Approve other wallet to transfer ownership of Token
    function approve(address _to, uint256 _tokenId)
        external
    {
        require(msg.sender == tokenToOwner[_tokenId]);
        tokenApprovals[_tokenId] = _to;
        emit Approval(msg.sender, _to, _tokenId);
    }

    // Return approved address for specific Token
    function getApproved(uint256 tokenId)
        external
        view
        returns(address operator)
    {
        require(_exists(tokenId));
        return tokenApprovals[tokenId];
    }

    /**
     * Private function to clear current approval of a given token ID
     * Reverts if the given address is not indeed the owner of the token
     */
    function _clearApproval(address owner, uint256 tokenId) private {
        require(tokenToOwner[tokenId] == owner);
        require(_exists(tokenId));
        if (tokenApprovals[tokenId] != address(0)) {
            tokenApprovals[tokenId] = address(0);
        }
    }

    /*
     * Sets or unsets the approval of a given operator
     * An operator is allowed to transfer all tokens of the sender on their behalf 
     */
    function setApprovalForAll(address to, bool approved)
        external
    {
        require(to != msg.sender);
        operatorApprovals[msg.sender][to] = approved;
        emit ApprovalForAll(msg.sender, to, approved);
    }

    // Tells whether an operator is approved by a given owner
    function isApprovedForAll(address owner, address operator)
        external
        view
        returns(bool)
    {
        return operatorApprovals[owner][operator];
    }

    // Take ownership of Token - only for approved users
    function takeOwnership(uint256 _tokenId)
        public
    {
        require(_isApprovedOrOwner(msg.sender, _tokenId));
        address owner = this.ownerOf(_tokenId);
        this.transferFrom(owner, msg.sender, _tokenId);
    }

    // Check if Token exists
    function _exists(uint256 tokenId)
        internal
        view
        returns(bool)
    {
        address owner = tokenToOwner[tokenId];
        return owner != address(0);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId)
        internal
        view
        returns(bool) 
    {
        address owner = tokenToOwner[tokenId];
        // Disable solium check because of
        // https://github.com/duaraghav8/Solium/issues/175
        // solium-disable-next-line operator-whitespace
        return (spender == owner || this.getApproved(tokenId) == spender || this.isApprovedForAll(owner, spender));
    }

    // Check if Token is unique and doesn't exist yet
    modifier isUnique(string memory _name, uint256 _dna) {
        bool result = true;
        for(uint i = 0; i < tokens.length; i++) {
            if(keccak256(abi.encodePacked(tokens[i].name)) == keccak256(abi.encodePacked(_name)) && tokens[i].dna == _dna) {
                result = false;
            }
        }
        require(result);
        _;
    }

    // Returns whether the target address is a contract
    function isContract(address account)
        internal
        view
        returns(bool)
    {
        uint256 size;
        // XXX Currently there is no better way to check if there is a contract in an address
        // than to check the size of the code at that address.
        // See https://ethereum.stackexchange.com/a/14016/36603
        // for more details about how this works.
        // TODO Check this again before the Serenity release, because all addresses will be
        // contracts then.
        // solium-disable-next-line security/no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}
