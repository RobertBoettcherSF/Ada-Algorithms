pragma Ada_2022;
package Baseball_Game with SPARK_Mode => On is
   subtype Score is Natural range 0 .. 100;
   type Game is private;
   function New_Game return Game with Global => null;
   function Home_Score (G : Game) return Score with Global => null;
   function Away_Score (G : Game) return Score with Global => null;
   procedure Home_Run (G : in out Game) with Global => null, Pre => Home_Score (G) < Score'Last;
   procedure Away_Run (G : in out Game) with Global => null, Pre => Away_Score (G) < Score'Last;
   function Winner (G : Game) return Integer with Global => null;
private
   type Game is record Home : Score := 0; Away : Score := 0; end record;
end Baseball_Game;
