# HERE IS WHAT ALL THE TABLES LOOK LIKE #
SELECT * FROM NHL.arenas;
SELECT * FROM NHL.awards;
SELECT * FROM NHL.coaches;
SELECT * FROM NHL.coaches_on_teams;
SELECT * FROM NHL.draft_picks;
SELECT * FROM NHL.games;
SELECT * FROM NHL.general_managers;
SELECT * FROM NHL.goalies;
SELECT * FROM NHL.goalies_on_teams;
SELECT * FROM NHL.players;
SELECT * FROM NHL.players_on_teams;
SELECT * FROM NHL.teams;


# 1 - single table select - the standings
SELECT t.team_name,t.points,t.wins,t.losses,t.overtime_losses 
FROM NHL.teams t 
ORDER BY t.points DESC;

# 2 - inner join - players that played for the penguins
SELECT p.player_name,pt.points,t.team_name 
FROM NHL.teams t INNER JOIN NHL.players_on_teams pt ON t.pk_team_id = pt.fk_team_id 
INNER JOIN NHL.players p ON pt.fk_player_id = p.pk_player_id 
WHERE t.team_name = "Pittsburgh Penguins";

# 3 - left join - all games that the penguins played
SELECT t.team_name AS home_team,g.home_goal_total, tt.team_name AS visiting_team, g.visitor_goal_total, g.type_of_win 
FROM nhl.games g LEFT JOIN nhl.teams t ON g.fk_home_id=t.pk_team_id LEFT JOIN nhl.teams tt ON g.fk_visitor_id = tt.pk_team_id 
WHERE (g.fk_home_id = 23 AND g.home_goal_total > g.visitor_goal_total) OR (g.fk_visitor_id = 23 AND g.home_goal_total < g.visitor_goal_total);

# 4a - avg() - average age of all nhl players
SELECT AVG(p.age) FROM NHL.players p;

# 4b - count() - players that played for the most number of teams during the season
SELECT COUNT(pt.fk_player_id) AS number_of_teams, p.player_name 
FROM NHL.players_on_teams pt INNER JOIN NHL.players p ON p.pk_player_id=pt.fk_player_id 
INNER JOIN NHL.teams t ON pt.fk_team_id=t.pk_team_id GROUP BY p.pk_player_id 
ORDER BY number_of_teams DESC;

# 5 - group by - the average number of goals scored in a game grouped by the month the games are played in
SELECT SUBSTRING('JAN FEB MAR APR MAY JUN JUL AUG SEP OCT NOV DEC ', (MONTH(g.game_date) * 4) - 3, 3) AS month,AVG(g.home_goal_total+g.visitor_goal_total) AS average_goal_total 
FROM nhl.games g 
GROUP BY MONTH(g.game_date);

# 6 - having - players who scored 40 or more goals
SELECT p.player_name,p.goals 
FROM NHL.players p 
HAVING p.goals > 39 
ORDER BY p.goals DESC;

# 7 - order by - players who average the most ice time per game
SELECT p.player_name, p.time_on_ice/p.games_played AS average_time_on_ice,p.position,p.points 
FROM nhl.players p 
ORDER BY average_time_on_ice DESC;

# 8 - limit - top ten goalies on save percentage that played more than 20 games
SELECT (g.saves-g.goals_against)/g.saves AS save_percentage,g.goalie_name,g.games_played 
FROM NHL.goalies g WHERE g.games_played>20 
ORDER BY save_percentage DESC LIMIT 10; 

# 9 - subquery - highest scoring player for each team
SELECT t.team_name,p.player_name, p.points
FROM NHL.teams t INNER JOIN NHL.players_on_teams pt ON t.pk_team_id = pt.fk_team_id 
INNER JOIN NHL.players p ON p.pk_player_id = pt.fk_player_id 
WHERE p.points= (SELECT MAX(pp.points) FROM 
				NHL.teams tt INNER JOIN NHL.players_on_teams ptt ON tt.pk_team_id = ptt.fk_team_id 
				INNER JOIN NHL.players pp ON pp.pk_player_id = ptt.fk_player_id
				WHERE t.pk_team_id = tt.pk_team_id
				GROUP BY tt.team_name);
                
# 10 - subquery - the roster that won the stanley cup and their players ordered by highest scoring player
SELECT t.team_name,p.player_name,p.games_played,p.points FROM NHL.teams t INNER JOIN NHL.players_on_teams pt ON t.pk_team_id = pt.fk_team_id 
INNER JOIN NHL.players p ON p.pk_player_id = pt.fk_player_id 
WHERE t.team_name = (SELECT a.winner FROM NHL.awards a WHERE a.name_of_award = "Stanley Cup") 
ORDER BY p.points DESC;

##### Other queries #####

# Here is the query to calculate the standings from the game table
# i added the team points from the teams table to show my calculations were correct
SELECT DISTINCT
(SELECT (COUNT(g1.pk_game_id)) FROM NHL.games g1 WHERE (g1.fk_home_id=g.fk_home_id AND g1.home_goal_total>g1.visitor_goal_total) OR (g1.fk_visitor_id=g.fk_home_id AND g1.home_goal_total<g1.visitor_goal_total)) AS wins,
(SELECT COUNT(g2.pk_game_id) FROM NHL.games g2 WHERE (g2.fk_home_id=g.fk_home_id AND g2.home_goal_total<g2.visitor_goal_total AND (g2.type_of_win="REG")) OR (g2.fk_visitor_id=g.fk_home_id AND g2.home_goal_total>g2.visitor_goal_total AND (g2.type_of_win="REG"))) AS losses,
(SELECT COUNT(g3.pk_game_id) FROM NHL.games g3 WHERE (g3.fk_home_id=g.fk_home_id AND g3.home_goal_total<g3.visitor_goal_total AND (g3.type_of_win="OT" OR g3.type_of_win="SO")) OR (g3.fk_visitor_id=g.fk_home_id AND g3.home_goal_total>g3.visitor_goal_total AND (g3.type_of_win="OT" OR g3.type_of_win="SO"))) AS overtime_or_so_loss,
((SELECT (COUNT(g1.pk_game_id)) FROM NHL.games g1 WHERE (g1.fk_home_id=g.fk_home_id AND g1.home_goal_total>g1.visitor_goal_total) OR (g1.fk_visitor_id=g.fk_home_id AND g1.home_goal_total<g1.visitor_goal_total))*2)+
(SELECT COUNT(g3.pk_game_id) FROM NHL.games g3 WHERE (g3.fk_home_id=g.fk_home_id AND g3.home_goal_total<g3.visitor_goal_total AND (g3.type_of_win="OT" OR g3.type_of_win="SO")) OR (g3.fk_visitor_id=g.fk_home_id AND g3.home_goal_total>g3.visitor_goal_total AND (g3.type_of_win="OT" OR g3.type_of_win="SO"))) AS team_points,
t.team_name,t.points
FROM NHL.games g INNER JOIN NHL.teams t ON g.fk_home_id=t.pk_team_id INNER JOIN NHL.teams tt ON tt.pk_team_id=g.fk_visitor_id;


# the home and away win percentage for each team
# only two teams won more on the road than at home
SELECT DISTINCT t.team_name, 
(SELECT COUNT(g1.pk_game_id)/42 FROM NHL.games g1 WHERE g1.fk_home_id = g.fk_home_id AND g1.home_goal_total>g1.visitor_goal_total)*100 AS home_win_percentage,
(SELECT COUNT(g2.pk_game_id)/42 FROM NHL.games g2 WHERE g2.fk_visitor_id = g.fk_home_id AND g2.home_goal_total<g2.visitor_goal_total)*100 AS away_win_percentage,
(SELECT COUNT(g1.pk_game_id)/42 FROM NHL.games g1 WHERE g1.fk_home_id = g.fk_home_id AND g1.home_goal_total>g1.visitor_goal_total)*100-
(SELECT COUNT(g2.pk_game_id)/42 FROM NHL.games g2 WHERE g2.fk_visitor_id = g.fk_home_id AND g2.home_goal_total<g2.visitor_goal_total)*100 AS difference
FROM NHL.games g INNER JOIN NHL.teams t ON g.fk_home_id=t.pk_team_id;


# league average home team win percentage to fully show that the home team advantage is a real thing
SELECT COUNT(pk_game_id)/((SELECT COUNT(pk_game_id) FROM NHL.games gg WHERE gg.home_goal_total < gg.visitor_goal_total)+COUNT(pk_game_id)) AS league_wide_home_team_win_percentage FROM NHL.games g WHERE g.home_goal_total > g.visitor_goal_total;


# the lowested attended games
SELECT t.team_name AS home_team,tt.team_name AS away_team,g.attendance FROM nhl.games g INNER JOIN NHL.teams t ON t.pk_team_id=g.fk_home_id INNER JOIN NHL.teams tt ON tt.pk_team_id=g.fk_visitor_id ORDER BY g.attendance;


# teams sorted by average attendance
SELECT t.team_name,AVG(g.attendance) AS average_attendance,a.capacity,AVG(g.attendance)/a.capacity AS average_number_of_seats_filled FROM nhl.games g INNER JOIN NHL.teams t ON t.pk_team_id=g.fk_home_id INNER JOIN NHL.teams tt ON tt.pk_team_id=g.fk_visitor_id INNER JOIN NHL.arenas a ON t.fk_arena_id=a.pk_arena_id GROUP BY t.pk_team_id ORDER BY average_attendance;


# number of sellout crowds for each team
SELECT team.team_name,
(SELECT COUNT(a.capacity) FROM nhl.games g INNER JOIN NHL.teams t ON t.pk_team_id=g.fk_home_id INNER JOIN NHL.teams tt ON tt.pk_team_id=g.fk_visitor_id INNER JOIN NHL.arenas a ON t.pk_team_id=a.pk_arena_id WHERE t.pk_team_id=team.pk_team_id AND g.attendance>=a.capacity) AS number_of_sellouts,
(SELECT COUNT(a.capacity) FROM nhl.games g INNER JOIN NHL.teams t ON t.pk_team_id=g.fk_home_id INNER JOIN NHL.teams tt ON tt.pk_team_id=g.fk_visitor_id INNER JOIN NHL.arenas a ON t.pk_team_id=a.pk_arena_id WHERE t.pk_team_id=team.pk_team_id AND g.attendance>=a.capacity)/41*100 AS percentage_of_games_that_are_sellouts
FROM NHL.teams team ORDER BY number_of_sellouts DESC;


# number of coaches each team had
SELECT COUNT(c.coach_name) AS number_of_coaches,t.team_name FROM NHL.coaches_on_teams ct INNER JOIN NHL.coaches c ON ct.fk_coach_id=c.pk_coach_id INNER JOIN NHL.teams t ON ct.fk_team_id=t.pk_team_id GROUP BY t.pk_team_id ORDER BY number_of_coaches DESC;

# the average time on ice and points per 60 for players that have played more than 20 games and then order by points per 60
SELECT p.player_name, p.time_on_ice/p.games_played AS atoi, p.points/p.time_on_ice*60 AS points_per_60, p.points/p.games_played AS points_per_game FROM nhl.players p WHERE p.position <> "D" AND p.games_played > 20 ORDER BY points_per_60 DESC;


# the players that had the highest shooting percentage that played at least 40 games
SELECT p.player_name, p.goals/p.shots*100 AS shooting_percentage, p.goals FROM nhl.players p WHERE p.goals > 1 AND p.games_played > 40 ORDER BY shooting_percentage DESC;


#what teams had the best powerplay percentage vs adjusted power play percentage
# adjusted powerplay is something i created (im sure someone else has come up with the idea) but the way it works
# it takes short handed goals allowed into account when calculated power play percentage
# for example the penguins had a powerplay percentage of 24.5614 but they allowed a league highest 15 short handed goals against
# when you account for these goals they allowed on the power play their adjusted pp% drops to 17.9825
SELECT t.team_name, t.pp_goals/t.power_plays*100 AS power_play_percentage, (t.pp_goals-t.sh_goals_against)/t.power_plays*100 AS adjusted FROM NHL.teams t ORDER BY adjusted DESC;


# players who played for the most teams
SELECT COUNT(pt.fk_player_id)  AS number_of_teams, p.player_name FROM NHL.players_on_teams pt INNER JOIN NHL.players p ON p.pk_player_id=pt.fk_player_id INNER JOIN NHL.teams t ON pt.fk_team_id=t.pk_team_id GROUP BY p.pk_player_id ORDER BY number_of_teams DESC;


# teams that played the most goalies
SELECT COUNT(t.team_name) AS number_of_goalies,t.team_name FROM NHL.goalies_on_teams gt INNER JOIN NHL.goalies g ON gt.fk_goalie_id=g.pk_goalie_id INNER JOIN NHL.teams t ON gt.fk_team_id=t.pk_team_id GROUP BY t.team_name ORDER BY number_of_goalies DESC;


# all of the penguins draft picks - or any team just change the where statement
SELECT dp.overall,dp.draftee_name,t.team_name FROM NHL.teams t INNER JOIN NHL.draft_picks dp ON t.pk_team_id=dp.fk_team_id WHERE t.team_name = "Pittsburgh Penguins" ORDER BY dp.overall;


# each teams highest drafted player
SELECT t.team_name,dp.overall,dp.draftee_name FROM NHL.teams t INNER JOIN NHL.draft_picks dp ON t.pk_team_id=dp.fk_team_id GROUP BY t.team_name ORDER BY t.pk_team_id;


# sort games by the biggest blowouts - biggest blowout was when the penguins destroyed the calgary flames 9-1
SELECT t.team_name,g.home_goal_total,tt.team_name,g.visitor_goal_total,ABS(g.home_goal_total-g.visitor_goal_total) AS goal_differential FROM NHL.games g INNER JOIN NHL.teams t ON g.fk_home_id = t.pk_team_id INNER JOIN NHL.teams tt ON tt.pk_team_id = g.fk_visitor_id ORDER BY goal_differential DESC;


# highest scoring games of the season
SELECT t.team_name,g.home_goal_total,tt.team_name,g.visitor_goal_total, g.home_goal_total+g.visitor_goal_total AS total_goals FROM NHL.games g INNER JOIN NHL.teams t ON g.fk_home_id = t.pk_team_id INNER JOIN NHL.teams tt ON tt.pk_team_id = g.fk_visitor_id ORDER BY total_goals DESC;


# number of players selected from each amateur team
SELECT d.amateur_team, COUNT(d.amateur_team) AS number_of_players_drafted FROM NHL.draft_picks d GROUP BY d.amateur_team ORDER BY number_of_players_drafted DESC;


# number of players drafted from each league
SELECT COUNT(d.pk_draft_id) AS number_of_players_from_that_league,SUBSTRING_INDEX(SUBSTRING_INDEX(d.amateur_team,'(',-1),')',1) AS league FROM NHL.draft_picks d GROUP BY league ORDER BY number_of_players_from_that_league DESC;


# number of players from each country getting drafted
SELECT nationality ,COUNT(nationality) AS number_of_players_from_each_country FROM NHL.draft_picks GROUP BY nationality ORDER BY COUNT(nationality) DESC;


# teams that drafted the most players
SELECT t.team_name,COUNT(d.fk_team_id) AS number_of_draft_picks FROM NHL.draft_picks d INNER JOIN NHL.teams t ON t.pk_team_id = d.fk_team_id GROUP BY t.team_name ORDER BY number_of_draft_picks DESC;


# coaches with the highest win percentage of all time currenly coaching
SELECT coach_name,wins/games_coached FROM NHL.coaches ORDER BY wins/games_coached DESC;


# this stat is call goals save above average
# the amount of goals the goalie has saved compared to an average goalie
# a positive number means they are better than the average goalie
# a negative number means they are belwow average
SET @average_sv = (SELECT (SUM(shots_against)-SUM(goals_against))/SUM(shots_against) FROM NHL.goalies);
SELECT goalie_name AS name,TRUNCATE(shots_against-(shots_against)*@average_sv-goals_against,3) AS gsaa FROM NHL.goalies ORDER BY GSAA DESC;


# goals against average - common stat used to evaluate goalies
SELECT goalie_name AS name,g.goals_against/g.minutes*60 AS GAA FROM NHL.goalies g WHERE g.games_started>15 ORDER BY GAA;


# these are players that played more than 82 games in the regular season.
# there are only 82 games in a season so surely this must be an error in the data?
# nope, think about it
SELECT player_name,games_played FROM NHL.players WHERE games_played > 82 ORDER BY games_played DESC;

# i'll give you a hint - compare the players from this query to the last one
SELECT COUNT(pt.fk_player_id)  AS number_of_teams, p.player_name FROM NHL.players_on_teams pt INNER JOIN NHL.players p ON p.pk_player_id=pt.fk_player_id INNER JOIN NHL.teams t ON pt.fk_team_id=t.pk_team_id WHERE p.player_name = "Marcus Pettersson" OR p.player_name = "Kevin Fiala" OR p.player_name = "Ryan Hartman" GROUP BY p.pk_player_id ORDER BY number_of_teams DESC;

# its because they were traded mid season when their original team played more games than the team they were traded too
# the biggest instance of this was in 1992-93 when Jimmy Carson was traded from Detroit to Los Angeles and played 86 games in one season.
# the players get paid based on games played so maybe he made 4 games of overtime pay