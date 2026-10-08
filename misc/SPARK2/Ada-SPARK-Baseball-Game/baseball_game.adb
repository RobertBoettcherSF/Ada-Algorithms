pragma Ada_2022;
package body Baseball_Game with SPARK_Mode => On is
   function New_Game return Game is
   begin return (Home => 0, Away => 0); end New_Game;
   procedure Home_Run (G : in out Game) is begin if G.Home < Score'Last then G.Home := G.Home + 1; end if; end Home_Run;
   procedure Away_Run (G : in out Game) is begin if G.Away < Score'Last then G.Away := G.Away + 1; end if; end Away_Run;
   function Home_Score (G : Game) return Score is begin return G.Home; end Home_Score;
   function Away_Score (G : Game) return Score is begin return G.Away; end Away_Score;
   function Winner (G : Game) return Integer is
   begin if G.Home > G.Away then return 1; elsif G.Away > G.Home then return 2; else return 0; end if; end Winner;
end Baseball_Game;
