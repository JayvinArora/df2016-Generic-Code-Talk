public class AstroGenericRouter extends Router {

	// custom routing algorithm for astro public group
	public override void assign(List<SObject> records){


		//get the astro team members. the map is keyed by team name, and is lazy loaded
  	List<Id> astroMembers = new List<Id>(groupsAssignedToCountries.get(Constants.ASTRO));
		Integer membersSize = astroMembers.size();
		for(SObject rec : records)
		{
			//assign to default user
			if (astroMembers.isEmpty())
				rec.put('OwnerId', defaultUser.Id);
			else
			{ //assign randomly
				Integer index = Integer.valueOf(Math.random()* membersSize);
				rec.put('OwnerId', astroMembers[index]);
			}
		}
	}
}