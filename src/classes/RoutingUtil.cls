public with sharing class RoutingUtil {

  //default user to assign recs
  private static User defaultUser {
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


  /**
  *	checks if the lead is from a known country, and routes it to a
  * default user, or public group associated with the country.
  * Then the lead is assigned to a user based on that group's
  * process.
  * @param leadsToAssign are the list of leads that need to be assigned
  * @return nothing
  **/
  public static void routeLead(List<Lead> leadsToAssign)
  {
		//initialize variables
  	List<Lead> defaultUserAssignments = new List<Lead>();
  	List<Lead> astroAssignments = new List<Lead>();
  	List<Lead> lightningAssignments = new List<Lead>();
  	List<Lead> thunderAssignments = new List<Lead>();

  	//get a map of known countries and the public group assigned to each country
  	Map<String, Country_Team_Assignment__c> countryToAssignedTeams = Country_Team_Assignment__c.getAll();

  	//assign leads to the proper team
  	for (Lead leadRec : leadsToAssign)
  	{
  		//Is the lead from a known country?  No - assign to default user that's lazy loaded
  		if(!countryToAssignedTeams.containsKey(leadRec.Country))
  			leadRec.OwnerId = defaultUser.Id;
  		else
  		{
  		//Route leads from a known country to the assigned group
  			String countryGroup = countryToAssignedTeams.get(leadRec.Country).Assigned_Group__c;
  			if (countryGroup == Constants.ASTRO)
  				astroAssignments.add(leadRec);
  			else if(countryGroup == Constants.LIGHTNING)
  				lightningAssignments.add(leadRec);
  			else if(countryGroup == Constants.THUNDER)
  				thunderAssignments.add(leadRec);
  		}
  	}

		//assign lead records to users based on the team.	Each time has a unique routing mechanism
		assignLeadstoAstroMembers(astroAssignments);
		assignLeadsToLightningMembers(lightningAssignments);
		assignLeadsToThunderMembers(thunderAssignments);
  }

  public static void routeLeadsStrategy(List<Lead> leads){
    //get a map of known countries and the public group assigned to each country
    Map<String, Country_Team_Assignment__c> countryToAssignedTeams = Country_Team_Assignment__c.getAll();

    // sort leads in a map by the mapped public group
    Map<String, List<Lead>> leadMap = new Map<String, List<Lead>>();
    for(Lead lead :leads){
      String countryGroup = countryToAssignedTeams.get(lead.Country).Assigned_Group__c;

      if(leadMap.containsKey(countryGroup)) leadMap.get(countryGroup).add(lead);
      else leadMap.put(countryGroup, new List<Lead>{lead});
    }

    // iterate over public group to lead map
    for(String countryGroup :leadMap.keySet()){
      // get a type for a public group
      Type routerType = Type.forName(
        String.join(new List<String>{
          countryGroup,'Router'
        }, ''));

      // intantiate a custom router implementation and route the leads using its logic
      Router route = (Router)routerType.newInstance();
      route.assign(leadMap.get(countryGroup));
    }
  }






  /**
  * Assigns the leads to the astro team members. It gets the Astro group members
  * from a helper method.  If the group is empty, it assigns it to  the default user,
  * otherwise, it assigns them randomly
  * @param leadRecs the leadRecords assigned to the astro team
  * @return nothing
  **/
  public static void assignLeadstoAstroMembers(List<lead> leadRecs)
  {
  	//get the astro team members. the map is keyed by team name, and is lazy loaded
  	List<Id> astroMembers = new List<Id>(groupsAssignedToCountries.get(Constants.ASTRO));
		for(Lead leadRec : leadRecs)
		{
			//assign to default user
			if (astroMembers.isEmpty())
				leadRec.OwnerId = defaultUser.Id;
			else
			{ //assign randomly
				Integer randomNum = Math.roundToLong(Math.random()*(astroMembers.size() - 1)).intValue();
				leadRec.OwnerId = astroMembers[randomNum];
			}
		}
  }

  //assignment of leads to default user
  public static void assignLeadsToDefaultUser(List<Lead> leadRecs){
  	//...assign to defaultUser
  }

  // assignemet of leads to lightningMembers based on round robin
  public static void assignLeadsToLightningMembers(List<Lead> leadRecs)
  {
  	Set<Id> lightningMembers = groupsAssignedToCountries.get(Constants.LIGHTNING);
		//....
  }

  // assignment of leads to thunder members based on sales rankings
  public static void assignLeadsToThunderMembers(List<Lead> leadRecs)
  {
  	Set<Id> thunderMembers = groupsAssignedToCountries.get(Constants.THUNDER);
		//....
  }





  /**
  * A map of the Group's Name -> Set of Users's that are direct members of the Group.
  * only goes 1 level deep in the group heiarchy.
  **/
  private static Map<String, Set<Id>> groupsAssignedToCountries{
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