pragma Ada_2022;
package body Design_A_Leaderboard with SPARK_Mode => On is
   procedure Initialize is begin Current := 0; Seen := False; end Initialize;
   procedure Submit (Score : Integer) is begin if (not Seen) or else Score > Current then Current := Score; end if; Seen := True; end Submit;
   function Best return Integer is (Current); function Has_Score return Boolean is (Seen);
end Design_A_Leaderboard;
