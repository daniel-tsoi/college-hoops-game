local Config = {}
Config.Cooldown = 12 * 60 * 60
Config.Denominator = 1000
-- Display slices are equal; these explicit probabilities govern the server draw.
Config.Rewards = table.freeze({
 table.freeze({id="HOF",label="HOF PLAYER",chance=2.5,tickets=25}),
 table.freeze({id="NonCollege",label="NON-COLLEGE",chance=2.5,tickets=25}),
 table.freeze({id="Cash100",label="$100,000",chance=20,tickets=200,cash=100000}),
 table.freeze({id="Cash50",label="$50,000",chance=35,tickets=350,cash=50000}),
 table.freeze({id="Cash15",label="$15,000",chance=40,tickets=400,cash=15000}),
})
return table.freeze(Config)
