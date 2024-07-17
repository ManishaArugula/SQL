--statistical analysis on Indian Census Data 

select count(*) from data1

select count(*) from data2

select sum(population) as total_population from Data2

select (avg(growth) * 100) as avg_growth from Data1

select top 3  [State],round((avg(growth) * 100),0) as avg_growth from Data1
group by [State]
order by avg_growth desc

select  [State],round(avg(sex_ratio),0)  as avg_sex_ratio from Data1
group by [State]
order by avg_sex_ratio desc

select round(avg(literacy), 0) as avg_literacy, [State] from Data1
group by [State]
having  round(avg(literacy), 0)> 90


---display the top 3 states in literacy and bottom 3 in the literacy
--using a temporary table

drop table if exists #top_states
create table #top_states
( [state] nvarchar(255),
[avg_literacy] float)

insert into #top_states 
select top 3 [State],  round(avg(literacy), 0) as avg_literacy from Data1
group by [State]
order by avg_literacy desc

select * from #top_states

drop table if exists #bottom_states
create table #bottom_states
( [state] nvarchar(255),
[avg_literacy] float)

insert into #bottom_states 
select top 3 [State],  round(avg(literacy), 0) as avg_literacy from Data1
group by [State]
order by avg_literacy 

select * from #bottom_states
union all
select * from #top_states


----states starting with letter a
select distinct state from Data1
where state like 'a%'

--states with a or b
select distinct state from Data1
where state like '[a,b]%'

--states start with t and end with a
select distinct state from Data1
where state like 't%'  and state like '%a'

-----get population of men and women

--Deriving the formula
--female/male =sex_ratio  --1
---female+male = population --2
---female =population -male --3
--put equation 3 in 1 
---(sex_ratio* male) = population-male
--(sex_ratio *male)+male =population
---population =male(sex_ratio)+1
--male =population/(sex_ratio)+1
---Derive the same for female

--female =pop -male
--female =pop - pop/(sex_ratio+1)
--female =pop(1-1/(sex_ratio +1)) --simplify

--Always join on the highest level of granualarity 

select distinct District,sex_ratio ,round(a.Population/(a.Sex_Ratio+1),0) as males, round((Sex_Ratio * population)/(sex_ratio+1),0) as female
from (
select c.District,c.State,c.Sex_Ratio/1000 as sex_ratio,d.Population from data1 as c
join data2 as d on
c.District=d.District) as a
order by District 

---Give women and men population accroding to state
select state, sum(males),sum(female) from
(select distinct District,sex_ratio,State ,round(a.Population/(a.Sex_Ratio+1),0) as males, round((Sex_Ratio * population)/(sex_ratio+1),0) as female
from (
select c.District,c.State,c.Sex_Ratio/1000 as sex_ratio,d.Population from data1 as c
join data2 as d on
c.District=d.District) as a
) as b

group by state


---Calculate literacy rate 
--literacy = literacy_ratio* population
--illiteracy = (1-literacy_ratio)* population

select District,literacy_ratio,Population, round((literacy_ratio*Population),0) as total_literacy, round((1-literacy_ratio)*Population,0) as total_illiteracy from (
select a.District,a.State,(a.Literacy/100) as literacy_ratio ,b.Population
	from Data1 as a
join Data2 as b on a.District =b.District) as c

----Calculate previous census population,
--current_pop =previous_pop +(previous_pop* growth)
--previou_pop(1+growth) =current_pop
--previous_pop =current_pop/(1+growth)

select District,Growth, round(Population/(1+Growth),0) as previous_census_population,Population as current_census_population
from	
(select d1.District, d1.State,d1.Growth,d2.Population from Data1 as d1
join Data2 as d2 on d1.District=d2.District) as a
order by District

--- calculate previous census according to the state

select State, sum(previous_census_population) as previous_population, sum(current_census_population) as current_population from (
select District,state,Growth, round(Population/(1+Growth),0) as previous_census_population,Population as current_census_population
from	
(select d1.District, d1.State,d1.Growth,d2.Population from Data1 as d1
join Data2 as d2 on d1.District=d2.District) as a
) as b
group by State

----To calculate previous and current census for India

select sum(previous_population) as previous_census, sum(current_population) as current_census from (
select State, sum(previous_census_population) as previous_population, sum(current_census_population) as current_population from (
select District,state,Growth, round(Population/(1+Growth),0) as previous_census_population,Population as current_census_population
from	
(select d1.District, d1.State,d1.Growth,d2.Population from Data1 as d1
join Data2 as d2 on d1.District=d2.District) as a
) as b
group by State) as m

--Total area occupied by India
select sum(Area_km2) as area from Data2

--population density in previous and current census 
go

with cte as (
select census.*,area.* from (
select 1 as id1, sum(previous_population) as previous_census, sum(current_population) as current_census from (
select State, sum(previous_census_population) as previous_population, sum(current_census_population) as current_population from (
select District,state,Growth, round(Population/(1+Growth),0) as previous_census_population,Population as current_census_population
from	
(select d1.District, d1.State,d1.Growth,d2.Population from Data1 as d1
join Data2 as d2 on d1.District=d2.District) as a
) as b
group by State) as m) census
join
(select  1 as id2, sum(Area_km2) as area_in_km2 from Data2) area on census.id1=area.id2
)

select (previous_census/area_in_km2) as previous_population_density, (current_census/area_in_km2) as current_population_denisty  from cte

---top 3 district from each state that has highest literacy rate

select a.* from
(select District,State,literacy,rank() over(partition by state order by literacy desc) as ranking
from Data1)a
where ranking<=3