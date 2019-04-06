pragma solidity ^0.4.17;

contract CampaignFactory {
    address[] public deployedCampaigns;

    function createCampaign(uint minimum) public {
        // new campaign that gets deployed to the blockchain
        address newCampaign = new Campaign(minimum, msg.sender);
        deployedCampaigns.push(newCampaign);
    }
// view means no data in the function is modified
    function getDeployedCampaigns() public view returns (address[]) {
        return deployedCampaigns;
    }
}

// constructor function
contract Campaign {
    struct Request {
        string description;
        uint value;
        address recipient;
        bool complete;
        // Number of yes votes
        uint approvalCount;
        mapping(address => bool) approvals;
    }

    // Storage Variables

    Request[] public requests;
    // Manger - address of the person who is making this campaign
    address public manager;
    // Minimum donation required to be considered a contributor or 'approver'
    uint public minimumContribution;
    // List of addresses for every person who has donated money
    mapping(address => bool) public approvers;
    // The amount of approvers
    uint public approversCount;

    modifier restricted() {
        require(msg.sender == manager);
        _;
    }
    // Sets the miminum contribution and the owner
    function Campaign(uint minimum, address creator) public {
        manager = creator;
        minimumContribution = minimum;
    }

    // Called when someone wants to donate money to the campaign and
    // become an approver
    function contribute() public payable {
        require(msg.value > minimumContribution);

        approvers[msg.sender] = true;
        approversCount++;
    }

// Called by the manager to create a new 'spending' request
    function createRequest(string description, uint value, address recipient) public restricted {
        // create brand new request object, local variable so 
        // automatically created in memory
        // use a mapping instead of an array so we save on gas
        Request memory newRequest = Request({
           description: description,
           value: value,
           recipient: recipient,
           complete: false,
           approvalCount: 0
        });

        requests.push(newRequest);
    }
    // Called by each contributor to approve a spending request
    // Need to make sure a single contributor cannot vote mutiple times 
    // on a single spending request
    function approveRequest(uint index) public {
        Request storage request = requests[index];
    // Make sure person is a donator
        require(approvers[msg.sender]);
        // Make sure person has not voted on this request before
        require(!request.approvals[msg.sender]);
        // mark person as voted
        request.approvals[msg.sender] = true;
        // increment approvals by 1
        request.approvalCount++;
    }
    // Manager will call to finalize a request and get the request paid to the vendor
    // restricted because we only want manger to call this function
    function finalizeRequest(uint index) public restricted {
        // 'Request' specifies that we a creating a variable that is refering to
        // a request strut 
        Request storage request = requests[index];

        require(request.approvalCount > (approversCount / 2));
        require(!request.complete);

        request.recipient.transfer(request.value);
        request.complete = true;
    }

    function getSummary() public view returns (
      uint, uint, uint, uint, address
      ) {
        return (
          minimumContribution,
          this.balance,
          requests.length,
          approversCount,
          manager
        );
    }

    function getRequestsCount() public view returns (uint) {
        return requests.length;
    }
}
