public class AstroRouter extends Router {

	// custom routing algorithm for astro public group
	public override void assign(List<SObject> records){
		List<Lead> leads = (List<Lead>) records;
		
		//get the astro team members. the map is keyed by team name, and is lazy loaded
		List<Id> astroMembers = new List<Id>(groupsAssignedToCountries.get(Constants.ASTRO));
		Integer membersSize = astroMembers.size();
		for(Lead lead : leads)
		{
			//assign to default user
			if (astroMembers.isEmpty())
				lead.OwnerId = defaultUser.Id;
			else
			{ //assign randomly
				Integer index = Integer.valueOf(Math.random()* membersSize);
				lead.OwnerId = astroMembers[index];
			}
		}
	}
}