pragma Ada_2022;

package body Minimum_Window_Substring with SPARK_Mode => On is
   function Has_ABC_1 (A : Character) return Boolean is
   begin
      return (A = 'A') and then (A = 'B') and then (A = 'C');
   end Has_ABC_1;

   function Has_ABC_2 (A : Character; B : Character) return Boolean is
   begin
      return (A = 'A' or else B = 'A') and then (A = 'B' or else B = 'B') and then (A = 'C' or else B = 'C');
   end Has_ABC_2;

   function Has_ABC_3 (A : Character; B : Character; C : Character) return Boolean is
   begin
      return (A = 'A' or else B = 'A' or else C = 'A') and then (A = 'B' or else B = 'B' or else C = 'B') and then (A = 'C' or else B = 'C' or else C = 'C');
   end Has_ABC_3;

   function Has_ABC_4 (A : Character; B : Character; C : Character; D : Character) return Boolean is
   begin
      return (A = 'A' or else B = 'A' or else C = 'A' or else D = 'A') and then (A = 'B' or else B = 'B' or else C = 'B' or else D = 'B') and then (A = 'C' or else B = 'C' or else C = 'C' or else D = 'C');
   end Has_ABC_4;

   function Has_ABC_5 (A : Character; B : Character; C : Character; D : Character; E : Character) return Boolean is
   begin
      return (A = 'A' or else B = 'A' or else C = 'A' or else D = 'A' or else E = 'A') and then (A = 'B' or else B = 'B' or else C = 'B' or else D = 'B' or else E = 'B') and then (A = 'C' or else B = 'C' or else C = 'C' or else D = 'C' or else E = 'C');
   end Has_ABC_5;

   function Has_ABC_6 (A : Character; B : Character; C : Character; D : Character; E : Character; F : Character) return Boolean is
   begin
      return (A = 'A' or else B = 'A' or else C = 'A' or else D = 'A' or else E = 'A' or else F = 'A') and then (A = 'B' or else B = 'B' or else C = 'B' or else D = 'B' or else E = 'B' or else F = 'B') and then (A = 'C' or else B = 'C' or else C = 'C' or else D = 'C' or else E = 'C' or else F = 'C');
   end Has_ABC_6;

   function Has_ABC_7 (A : Character; B : Character; C : Character; D : Character; E : Character; F : Character; G : Character) return Boolean is
   begin
      return (A = 'A' or else B = 'A' or else C = 'A' or else D = 'A' or else E = 'A' or else F = 'A' or else G = 'A') and then (A = 'B' or else B = 'B' or else C = 'B' or else D = 'B' or else E = 'B' or else F = 'B' or else G = 'B') and then (A = 'C' or else B = 'C' or else C = 'C' or else D = 'C' or else E = 'C' or else F = 'C' or else G = 'C');
   end Has_ABC_7;

   function Has_ABC_8 (A : Character; B : Character; C : Character; D : Character; E : Character; F : Character; G : Character; H : Character) return Boolean is
   begin
      return (A = 'A' or else B = 'A' or else C = 'A' or else D = 'A' or else E = 'A' or else F = 'A' or else G = 'A' or else H = 'A') and then (A = 'B' or else B = 'B' or else C = 'B' or else D = 'B' or else E = 'B' or else F = 'B' or else G = 'B' or else H = 'B') and then (A = 'C' or else B = 'C' or else C = 'C' or else D = 'C' or else E = 'C' or else F = 'C' or else G = 'C' or else H = 'C');
   end Has_ABC_8;

   function Minimum (Input : Text_Array) return Result is
   begin
      if Has_ABC_1 (Input (1)) then
         return 1;
      end if;
      if Has_ABC_1 (Input (2)) then
         return 1;
      end if;
      if Has_ABC_1 (Input (3)) then
         return 1;
      end if;
      if Has_ABC_1 (Input (4)) then
         return 1;
      end if;
      if Has_ABC_1 (Input (5)) then
         return 1;
      end if;
      if Has_ABC_1 (Input (6)) then
         return 1;
      end if;
      if Has_ABC_1 (Input (7)) then
         return 1;
      end if;
      if Has_ABC_1 (Input (8)) then
         return 1;
      end if;
      if Has_ABC_2 (Input (1), Input (2)) then
         return 2;
      end if;
      if Has_ABC_2 (Input (2), Input (3)) then
         return 2;
      end if;
      if Has_ABC_2 (Input (3), Input (4)) then
         return 2;
      end if;
      if Has_ABC_2 (Input (4), Input (5)) then
         return 2;
      end if;
      if Has_ABC_2 (Input (5), Input (6)) then
         return 2;
      end if;
      if Has_ABC_2 (Input (6), Input (7)) then
         return 2;
      end if;
      if Has_ABC_2 (Input (7), Input (8)) then
         return 2;
      end if;
      if Has_ABC_3 (Input (1), Input (2), Input (3)) then
         return 3;
      end if;
      if Has_ABC_3 (Input (2), Input (3), Input (4)) then
         return 3;
      end if;
      if Has_ABC_3 (Input (3), Input (4), Input (5)) then
         return 3;
      end if;
      if Has_ABC_3 (Input (4), Input (5), Input (6)) then
         return 3;
      end if;
      if Has_ABC_3 (Input (5), Input (6), Input (7)) then
         return 3;
      end if;
      if Has_ABC_3 (Input (6), Input (7), Input (8)) then
         return 3;
      end if;
      if Has_ABC_4 (Input (1), Input (2), Input (3), Input (4)) then
         return 4;
      end if;
      if Has_ABC_4 (Input (2), Input (3), Input (4), Input (5)) then
         return 4;
      end if;
      if Has_ABC_4 (Input (3), Input (4), Input (5), Input (6)) then
         return 4;
      end if;
      if Has_ABC_4 (Input (4), Input (5), Input (6), Input (7)) then
         return 4;
      end if;
      if Has_ABC_4 (Input (5), Input (6), Input (7), Input (8)) then
         return 4;
      end if;
      if Has_ABC_5 (Input (1), Input (2), Input (3), Input (4), Input (5)) then
         return 5;
      end if;
      if Has_ABC_5 (Input (2), Input (3), Input (4), Input (5), Input (6)) then
         return 5;
      end if;
      if Has_ABC_5 (Input (3), Input (4), Input (5), Input (6), Input (7)) then
         return 5;
      end if;
      if Has_ABC_5 (Input (4), Input (5), Input (6), Input (7), Input (8)) then
         return 5;
      end if;
      if Has_ABC_6 (Input (1), Input (2), Input (3), Input (4), Input (5), Input (6)) then
         return 6;
      end if;
      if Has_ABC_6 (Input (2), Input (3), Input (4), Input (5), Input (6), Input (7)) then
         return 6;
      end if;
      if Has_ABC_6 (Input (3), Input (4), Input (5), Input (6), Input (7), Input (8)) then
         return 6;
      end if;
      if Has_ABC_7 (Input (1), Input (2), Input (3), Input (4), Input (5), Input (6), Input (7)) then
         return 7;
      end if;
      if Has_ABC_7 (Input (2), Input (3), Input (4), Input (5), Input (6), Input (7), Input (8)) then
         return 7;
      end if;
      if Has_ABC_8 (Input (1), Input (2), Input (3), Input (4), Input (5), Input (6), Input (7), Input (8)) then
         return 8;
      end if;
      return 0;
   end Minimum;
end Minimum_Window_Substring;
