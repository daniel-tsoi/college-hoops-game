-- Mutually exclusive tickets: HOF 75/60000 = 1/800,
-- non-college 80/60000 = 1/750, All-Star 600/60000 = 1/100.
-- A special tier falls back to ordinary college if no purchased card fits the position.
return table.freeze({
 Denominator = 60000,
 Tickets = table.freeze({
  HOF = table.freeze({first=1, last=75, count=75}),
  NonCollege = table.freeze({first=76, last=155, count=80}),
  ["All-Star"] = table.freeze({first=156, last=755, count=600}),
  Ordinary = table.freeze({first=756, last=60000, count=59245}),
 }),
 HOFCardIds = table.freeze({
  "hof-magic-johnson-1978-79", "hof-michael-jordan-1983-84", "hof-shaquille-oneal-1991-92",
  "hof-oscar-robertson-1959-60", "hof-pete-maravich-1969-70", "hof-jayson-tatum-2016-17",
  "hof-derrick-rose-2007-08", "hof-kyrie-irving-2010-11",
 }),
 HOFChance = 1/800, NonCollegeChance = 1/750, AllStarChance = 1/100,
 Positions = table.freeze({"PG", "SG", "SF", "PF", "C"}),
})
