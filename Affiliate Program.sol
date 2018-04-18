pragma solidity ^0.4.21;
//interface
interface Token{
    function transfer(address from,uint256 value)public;
}
//contract creation
contract affiliator{
    struct user{
        address userAddress;
        uint256 amount;
        bytes32 code;
        bool exists;
        uint256 tokens;
    }
    //modifier for owner access
    modifier onlyowner{
        require(owner==msg.sender);
        _;
    }
    //Address of contract owner
    address owner;
    mapping(address => user) users;
    mapping(address => bool) AlreadyExists;
    mapping(address=> uint256) tokenvalue;
    Token public obj;
    //stores address of all users
    address[] storeadd;
    //stores PromoCode
    bytes32[] storeref;
    uint256 time;
    uint256 public fundRaised;
    uint256 public tokensfor1ether;
    uint256 public maxGoal;
    bool AlreadyTransfered;
   
    /*@constructor
        intialization
     @param TokenAddress- address of TokenAddress
     @param _tokensfor1ether- token value for 1 ethers
     @param durationinmin- end time in minutes of ICO
     @param _maxGoal- hardcap or maximum goal in ether
    */
    function affiliator(address TokenAddress,uint256 _tokensfor1ether,uint256 durationinmin,uint256 _maxGoal)public{
        
        obj=Token(TokenAddress);
        time=now *1000 + durationinmin *60000;
        tokensfor1ether=_tokensfor1ether;
        maxGoal=_maxGoal*1e18;
        owner=msg.sender;
    }
    /*@BuyTokens
        user register by using their address and if they have any ReferalCode
        they can use it otherwise enter 0 as ReferalCode and need to pay the ether
        and in return they will get tokens
        if they PromoCode then owner of the promocode will get extra tokens
        
     @param _userAddress-  Address of user
     @param ReferalCode-   PromoCode of another user enter 0 as PromoCode 
     @returns bytes32-   returns PromoCode for the user registered
    */
    function BuyTokens(address _userAddress,bytes32 ReferalCode)payable public returns(bytes32){
        require(AlreadyExists[_userAddress]==false);
        require((now*1000)<time && fundRaised < maxGoal); 
        if(ReferalCode=="0"){
            fundRaised+=msg.value;
            reg(_userAddress,ReferalCode);
            AlreadyExists[_userAddress]=true;
            return(users[_userAddress].code);
        }
        else{
           fundRaised+=msg.value;
            for(uint256 i=0;i<storeadd.length;i++){
              if(users[storeadd[i]].code==ReferalCode){
                   reg(_userAddress,ReferalCode);
               tokenvalue[storeadd[i]]+=users[storeadd[i]].tokens/10;
              }  
            }
            AlreadyExists[_userAddress]=true;
            return users[_userAddress].code;
        }
      
    }
    //internal function
    function reg(address _userAddress,bytes32 ReferalCode)internal{
         var u=users[_userAddress] ;
        u.userAddress=_userAddress;
        u.amount=msg.value;
        storeadd.push(_userAddress);
        u.code=keccak256(_userAddress);
        storeref.push(u.code);
        u.tokens=u.amount * tokensfor1ether;
        obj.transfer(_userAddress,u.tokens);
       
        
    }
    /*@timecheck
        This function checks the ico end time is reached or not
        and returns bool value
    */
     function timecheck()public constant returns(bool){
         if((now*1000)>time){
             return true;
         }
         else
         {
             return false;
         }
     }
     
    /*@getExtraTokens
        this function is used when a user uses a ReferalCode then the owner of
        the ReferalCode has some bonus tokens alloted if that user enter that ReferalCode
        then it will transfer that extra tokens to his address
     @param ReferalCode PromoCode
    */
    function getExtraTokens(bytes32 ReferalCode)public{
        for(uint256 i=0;i<storeadd.length;i++){
            if(users[storeadd[i]].code==ReferalCode){
                obj.transfer(users[storeadd[i]].userAddress,tokenvalue[storeadd[i]]);
                  tokenvalue[storeadd[i]]-=tokenvalue[storeadd[i]];
            }
             
            
        }
        
    }
    /*ethers
        In this function if maxGoal has reached before the ICO endtime 
        then ether will be sent to the contract owner if maxGoal has not reached
        even the ico has ended then ether will be sended to the users who are registered here
    */
    function ethers()public{
        if(((now*1000)>=time||(now*1000)<time) && fundRaised>=maxGoal){
            getEtherfromContract();
        }
        else if(now*1000>=time && fundRaised <maxGoal){
            RefundEthertoUsers();
        }
    }
    /*@getEtherfromContract
        internal function which sends ethers from contract 
        to the owner address
    */
    function getEtherfromContract()internal{
        owner.transfer(this.balance);
    }
    /*@RefundEthertoUsers
        internal function which transfers ethers from contract to
        all users who are all sent here
    */
    function RefundEthertoUsers()internal{
        require(AlreadyTransfered==false);
        for(uint256 i=0;i<storeadd.length;i++){
            storeadd[i].transfer(users[storeadd[i]].amount);
        }
        AlreadyTransfered=true;
        
    }
    /*@showExtraToken
        it just shows when a user uses a PromoCode and register then
        owner of that PromoCode will get alloted with extra tokens
        they can check here whether it is alloted or not
    */
    function showExtraToken(bytes32 ReferalCode)public constant returns(uint256){
        for(uint256 i=0;i<storeadd.length;i++){
            if(users[storeadd[i]].code==ReferalCode){
                return (tokenvalue[storeadd[i]]);
            }
        }
    }
    
    /*@showusers
            This function returns all the user address and their PromoCodes
    */
    function showusers()public constant returns(address[],bytes32[]){
        return (storeadd,storeref);
    }
    /*@Burn
        this function will detroy the contract and burns all the tokens
    */
    function Burn()onlyowner public{
      selfdestruct(msg.sender);
    }
    
    
    
}
