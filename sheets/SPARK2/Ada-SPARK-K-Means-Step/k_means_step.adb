pragma Ada_2022;
package body K_Means_Step with SPARK_Mode => On is
   function Abs_Difference (A, B : Point) return Integer is
   begin
      if A >= B then
         return A - B;
      else
         return B - A;
      end if;
   end Abs_Difference;

   function Nearest (P, C1, C2 : Point) return Cluster is
   begin
      if Abs_Difference (P, C1) <= Abs_Difference (P, C2) then
         return 1;
      else
         return 2;
      end if;
   end Nearest;

   procedure Step
     (P : in Point; C1, C2 : in out Point; N1, N2 : in out Count) is
      Chosen : constant Cluster := Nearest (P, C1, C2);
   begin
      if Chosen = 1 then
         C1 := (C1 * N1 + P) / (N1 + 1);
         N1 := N1 + 1;
      else
         C2 := (C2 * N2 + P) / (N2 + 1);
         N2 := N2 + 1;
      end if;
   end Step;
end K_Means_Step;
