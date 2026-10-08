pragma Ada_2022;
package body Maximal_Square with SPARK_Mode => On is
   function All_2 (A : Matrix; R, C : Index) return Boolean
     with Pre => R <= Index'Last - 1 and C <= Index'Last - 1 is
   begin
      return A (R, C) = 1 and A (R + 1, C) = 1 and A (R, C + 1) = 1 and A (R + 1, C + 1) = 1;
   end All_2;
   function All_3 (A : Matrix; R, C : Index) return Boolean
     with Pre => R <= Index'Last - 2 and C <= Index'Last - 2 is
   begin
      return All_2 (A, R, C) and All_2 (A, R + 1, C) and All_2 (A, R, C + 1) and A (R + 2, C + 2) = 1;
   end All_3;
   function All_4 (A : Matrix) return Boolean is
   begin
      return All_3 (A, 1, 1) and A (1, 4) = 1 and A (2, 4) = 1 and A (3, 4) = 1 and A (4, 1) = 1 and A (4, 2) = 1 and A (4, 3) = 1 and A (4, 4) = 1;
   end All_4;
   function Any_1 (A : Matrix) return Boolean is
   begin
      return A (1, 1) = 1 or A (1, 2) = 1 or A (1, 3) = 1 or A (1, 4) = 1 or A (2, 1) = 1 or A (2, 2) = 1 or A (2, 3) = 1 or A (2, 4) = 1 or A (3, 1) = 1 or A (3, 2) = 1 or A (3, 3) = 1 or A (3, 4) = 1 or A (4, 1) = 1 or A (4, 2) = 1 or A (4, 3) = 1 or A (4, 4) = 1;
   end Any_1;
   function Any_2 (A : Matrix) return Boolean is
   begin
      return All_2 (A, 1, 1) or All_2 (A, 1, 2) or All_2 (A, 1, 3) or All_2 (A, 2, 1) or All_2 (A, 2, 2) or All_2 (A, 2, 3) or All_2 (A, 3, 1) or All_2 (A, 3, 2) or All_2 (A, 3, 3);
   end Any_2;
   function Largest_Side (A : Matrix) return Side is
   begin
      if All_4 (A) then return 4;
      elsif All_3 (A, 1, 1) or All_3 (A, 1, 2) or All_3 (A, 2, 1) or All_3 (A, 2, 2) then return 3;
      elsif Any_2 (A) then return 2;
      elsif Any_1 (A) then return 1;
      else return 0;
      end if;
   end Largest_Side;
end Maximal_Square;
