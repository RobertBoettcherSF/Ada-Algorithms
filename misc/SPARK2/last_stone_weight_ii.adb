pragma Ada_2022;
package body Last_Stone_Weight_II with SPARK_Mode => On is
   function Difference (Total, Part : Remaining) return Long_Long_Integer is
      Difference_Value : constant Long_Long_Integer := Long_Long_Integer (Total) - 2 * Long_Long_Integer (Part);
   begin
      if Difference_Value < 0 then
         return -Difference_Value;
      else
         return Difference_Value;
      end if;
   end Difference;

   function Min_Remaining_Weight (A : Stones) return Long_Long_Integer is
      Total : constant Remaining := A (1) + A (2) + A (3) + A (4) + A (5) + A (6);
      Best : Long_Long_Integer := Long_Long_Integer (Total);
      P1 : constant Remaining := A (1);
      P2 : constant Remaining := A (1) + A (2);
      P3 : constant Remaining := A (1) + A (3);
      P4 : constant Remaining := A (1) + A (4);
      P5 : constant Remaining := A (1) + A (5);
      P6 : constant Remaining := A (2);
      P7 : constant Remaining := A (2) + A (3);
      P8 : constant Remaining := A (2) + A (4);
      P9 : constant Remaining := A (2) + A (5);
      P10 : constant Remaining := A (3);
      P11 : constant Remaining := A (3) + A (4);
      P12 : constant Remaining := A (3) + A (5);
      P13 : constant Remaining := A (4);
      P14 : constant Remaining := A (4) + A (5);
      P15 : constant Remaining := A (5);
      P16 : constant Remaining := A (1) + A (2) + A (3);
      P17 : constant Remaining := A (1) + A (2) + A (4);
      P18 : constant Remaining := A (1) + A (2) + A (5);
      P19 : constant Remaining := A (1) + A (3) + A (4);
      P20 : constant Remaining := A (1) + A (3) + A (5);
      P21 : constant Remaining := A (1) + A (4) + A (5);
      P22 : constant Remaining := A (2) + A (3) + A (4);
      P23 : constant Remaining := A (2) + A (3) + A (5);
      P24 : constant Remaining := A (2) + A (4) + A (5);
      P25 : constant Remaining := A (3) + A (4) + A (5);
      P26 : constant Remaining := A (1) + A (2) + A (3) + A (4);
      P27 : constant Remaining := A (1) + A (2) + A (3) + A (5);
      P28 : constant Remaining := A (1) + A (2) + A (4) + A (5);
      P29 : constant Remaining := A (1) + A (3) + A (4) + A (5);
      P30 : constant Remaining := A (2) + A (3) + A (4) + A (5);
      P31 : constant Remaining := A (1) + A (2) + A (3) + A (4) + A (5);
   begin
      if Difference (Total, P1) < Best then Best := Difference (Total, P1); end if;
      if Difference (Total, P2) < Best then Best := Difference (Total, P2); end if;
      if Difference (Total, P3) < Best then Best := Difference (Total, P3); end if;
      if Difference (Total, P4) < Best then Best := Difference (Total, P4); end if;
      if Difference (Total, P5) < Best then Best := Difference (Total, P5); end if;
      if Difference (Total, P6) < Best then Best := Difference (Total, P6); end if;
      if Difference (Total, P7) < Best then Best := Difference (Total, P7); end if;
      if Difference (Total, P8) < Best then Best := Difference (Total, P8); end if;
      if Difference (Total, P9) < Best then Best := Difference (Total, P9); end if;
      if Difference (Total, P10) < Best then Best := Difference (Total, P10); end if;
      if Difference (Total, P11) < Best then Best := Difference (Total, P11); end if;
      if Difference (Total, P12) < Best then Best := Difference (Total, P12); end if;
      if Difference (Total, P13) < Best then Best := Difference (Total, P13); end if;
      if Difference (Total, P14) < Best then Best := Difference (Total, P14); end if;
      if Difference (Total, P15) < Best then Best := Difference (Total, P15); end if;
      if Difference (Total, P16) < Best then Best := Difference (Total, P16); end if;
      if Difference (Total, P17) < Best then Best := Difference (Total, P17); end if;
      if Difference (Total, P18) < Best then Best := Difference (Total, P18); end if;
      if Difference (Total, P19) < Best then Best := Difference (Total, P19); end if;
      if Difference (Total, P20) < Best then Best := Difference (Total, P20); end if;
      if Difference (Total, P21) < Best then Best := Difference (Total, P21); end if;
      if Difference (Total, P22) < Best then Best := Difference (Total, P22); end if;
      if Difference (Total, P23) < Best then Best := Difference (Total, P23); end if;
      if Difference (Total, P24) < Best then Best := Difference (Total, P24); end if;
      if Difference (Total, P25) < Best then Best := Difference (Total, P25); end if;
      if Difference (Total, P26) < Best then Best := Difference (Total, P26); end if;
      if Difference (Total, P27) < Best then Best := Difference (Total, P27); end if;
      if Difference (Total, P28) < Best then Best := Difference (Total, P28); end if;
      if Difference (Total, P29) < Best then Best := Difference (Total, P29); end if;
      if Difference (Total, P30) < Best then Best := Difference (Total, P30); end if;
      if Difference (Total, P31) < Best then Best := Difference (Total, P31); end if;
      return Best;
   end Min_Remaining_Weight;
end Last_Stone_Weight_II;
