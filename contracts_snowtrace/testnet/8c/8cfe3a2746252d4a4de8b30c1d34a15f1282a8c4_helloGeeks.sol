/**
 *Submitted for verification at testnet.snowtrace.io on 2022-02-07
*/

// Creating a contract
contract helloGeeks
{ 
  // Initialising mapping of user balance
  mapping(address => uint8) balance;
   
  // Function to insert user balance
 
  function Insert(address _user, uint8 _amount) public {
    //insert the amount to a specific user
    balance[_user] = _amount;
  } 

  //function to view the balance
  function View(address _user) public view returns(uint8)
  {
    //see the value inside the mapping, it will return the balance of _user
    return balance[_user];
  } 
}