pragma Ada_2022;
package Design_A_Leaderboard with SPARK_Mode => On is
   procedure Initialize; procedure Submit (Score : Integer); function Best return Integer; function Has_Score return Boolean;
private Current : Integer := 0; Seen : Boolean := False;
end Design_A_Leaderboard;
