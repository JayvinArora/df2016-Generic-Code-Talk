public abstract class Router {

  // default routing alorithm which we can override in our individual subclasses
  public virtual void assign(List<SObject> records){
    for(SObject rec : records){
			rec.put('OwnerId', defaultUser.Id);
		}
  }

	protected User defaultUser {
    get{
      if (defaultUser == null){
         defaultUser = [
          SELECT Id
          FROM User
          WHERE Profile.Name = 'System Administrator' AND isActive = true
          LIMIT 1];
      }
      return defaultUser;
    }
    private set;
  }

  protected Map<String, Set<Id>> groupsAssignedToCountries{
  	get{
  		if (groupsAssignedToCountries == null)
  		{
  			Set<String> countryAssignments = new Set<String>();
  			//get the group name associated with the known countries
  			for (Country_Team_Assignment__c rec : Country_Team_Assignment__c.getAll().values())
  			{
  				countryAssignments.add(rec.Assigned_Group__c);
  			}
  			//get the group and group members for the groups assigned to the known countries
  			groupsAssignedToCountries = new Map<String, Set<Id>>();
  			for(Group g: [
			  			SELECT DeveloperName, Name,
			  				(
				  				SELECT Id, UserOrGroupId
				  				FROM GroupMembers
			  				)
			  			FROM Group
			  			WHERE
			  				DeveloperName IN :countryAssignments AND
			  				Type = 'Regular'
  			])
  			{
  				//since a group member can be a user / group, we get the users 1 level deep
  				Set<Id> groupMemberUsers = new Set<Id>();
  				for(GroupMember gm: g.GroupMembers)
  				{
  					if(gm.UserOrGroupId.getSObjectType() == User.sObjectType)
  						groupMemberUsers.add(gm.UserOrGroupId);
  				}
  				//map of group name to group members
  				groupsAssignedToCountries.put(g.DeveloperName, groupMemberUsers);
  			}
  		}
  		return groupsAssignedToCountries;
  	}
  	set;
	}



}