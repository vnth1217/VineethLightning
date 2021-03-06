public class TestClass {
 
       public Account a {get;set;}
 	   public Contact c {get;set;}
       public User u {get;set;}
       public User newUser {get;set;}
       public String selectedProfileId {get;set;}
       public Boolean isDisabled {get;set;}
       public Boolean isNewUserFound {get;set;}
       public Boolean clickedButton {get;set;}
       
       //Constructor
       public TestClass() {
        	a = new Account();
        	c = new Contact();
        	u = new User();
        	newUser= new User();
        	isDisabled=false;	
        	System.debug('inside constructor');
        	isNewUserFound=false;
        	clickedButton = false;
    	}
    	
       public PageReference checkForNewUser(){
       	try{
       		System.debug('isNewUserFound: ' + isNewUserFound);
          if(isNewUserFound==true)
           	return null;
       	  
       	  System.debug('checking for new user with username:' + u.username);
       	  User usr = [select id, name, username from User where username=:u.username LIMIT 1];
       	  if(usr!=null && usr.username == u.username){
       	     newUser = usr;
       	     isNewUserFound = true;
       	     System.debug('great news - found user with userId: ' + newUser.id);
       	     System.debug('isNewUserFound: ' + isNewUserFound);
       	  }
       	  return null;
       	}catch(Exception ex){
       		System.debug('...didnt find user yet...');
       		return null;
       	}
       }	
       
       //Controller method invoked from the VF page button
       public PageReference createPortaluser(){
        try{
        	clickedButton = true;
        	//Create the Account
        	Id accountId = createAccount();
        	System.debug('successfully created account');
        	
        	//Create the Contact associated to the previously created Contact
	        Id contactId = createContact(accountId);
	        
	        //Since the user is created asynchronously, we want to do some data validation to ensure the proper fields are populated
	        if(selectedProfileId == null || u.username==null){
	        	if(selectedProfileId==null){
	        		ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR, 'Profile is required: Please select a profile to associate new user');
					ApexPages.addMessage(myMsg);
	        	}
	        	if(u.username==null){
	        	   ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR, 'Username is required: Please a username for the new user');
				   ApexPages.addMessage(myMsg);
	        	}
	        	return null;
	        }
        	
        	//Create the User
	        //NOTE - Must invoke a @future method to be able to create Account, Contacts, and Users in the same Apex Transaction
	        TestClass.createUser((String)contactId, c.Email, c.FirstName, c.lastname,u.Username,selectedProfileId);
	        
	        //Display success message to VF page
	        ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.INFO, 'Successfully created Portal Contact & User records.');
			ApexPages.addMessage(myMsg);
			 isDisabled=true;
	        return null;
        }catch(Exception ex){
        	//Display error message to VF page
        	ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage());
			ApexPages.addMessage(myMsg);
   	  	    return null;
        }
       }
       
    //Method to create the Account 
    public Id createAccount(){
         insert a;
         System.debug('successfully created test account with Id:' + a.id);
         return a.id;
    }
    
    //Method to create the Contact
    public Id createContact(Id acctId){
    	c.accountid=acctId;
		insert c;
		System.debug('successfully created test contact with Id:' + c.id);
		return c.id;
    }
    
    //Async method, using @future, to create the User record and associate it to the previously created Contact
    //This uses @future because you can not have mixed DML operations for standard objects (Account, Contact) and Setup objects(User)
    @future static void createUser(String contactId, String email, String firstName, String lastName, String userName, String profileId) {
        Database.DMLOptions dmo = new Database.DMLOptions();
		dmo.EmailHeader.triggerUserEmail = true;
    	User u = new User(alias = 'standt',
    		email=email, 
            emailencodingkey='UTF-8',
            lastname=lastname,
            languagelocalekey='en_US', 
            localesidkey='en_US',
            profileid = profileId,
            contactId=contactId,
            timezonesidkey='America/Los_Angeles',
            username=userName);
        
        u.setOptions(dmo);
        insert u;
    }

    public List<SelectOption> getCustomerPortalProfiles() {
    	//Execute query to get all profiles associated to Customer Portal
        Profile[] profiles = [Select p.name, p.id From Profile p];
   	 	List<SelectOption> options = new List<SelectOption>();
   	 	for(Profile p: profiles)
   	 		  options.add(new SelectOption(p.id,p.name));
   	 	return options;
    }
    
    public PageReference reset(){
        PageReference newpage = new PageReference('/apex/TestApge');
        newpage.getParameters().clear();
        newpage.setRedirect(true);
        return newpage;
    }
    
}