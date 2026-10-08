pragma Ada_2022;

package body Max_Consecutive_Ones_III with SPARK_Mode => On is
   function Zero (B : Bit) return Natural is
   begin
      if B = 0 then return 1; else return 0; end if;
   end Zero;

   function Valid_1 (A : Bit) return Boolean is
   begin
      return Zero (A) <= 2;
   end Valid_1;

   function Valid_2 (A : Bit; B : Bit) return Boolean is
   begin
      return Zero (A) + Zero (B) <= 2;
   end Valid_2;

   function Valid_3 (A : Bit; B : Bit; C : Bit) return Boolean is
   begin
      return Zero (A) + Zero (B) + Zero (C) <= 2;
   end Valid_3;

   function Valid_4 (A : Bit; B : Bit; C : Bit; D : Bit) return Boolean is
   begin
      return Zero (A) + Zero (B) + Zero (C) + Zero (D) <= 2;
   end Valid_4;

   function Valid_5 (A : Bit; B : Bit; C : Bit; D : Bit; E : Bit) return Boolean is
   begin
      return Zero (A) + Zero (B) + Zero (C) + Zero (D) + Zero (E) <= 2;
   end Valid_5;

   function Valid_6 (A : Bit; B : Bit; C : Bit; D : Bit; E : Bit; F : Bit) return Boolean is
   begin
      return Zero (A) + Zero (B) + Zero (C) + Zero (D) + Zero (E) + Zero (F) <= 2;
   end Valid_6;

   function Valid_7 (A : Bit; B : Bit; C : Bit; D : Bit; E : Bit; F : Bit; G : Bit) return Boolean is
   begin
      return Zero (A) + Zero (B) + Zero (C) + Zero (D) + Zero (E) + Zero (F) + Zero (G) <= 2;
   end Valid_7;

   function Valid_8 (A : Bit; B : Bit; C : Bit; D : Bit; E : Bit; F : Bit; G : Bit; H : Bit) return Boolean is
   begin
      return Zero (A) + Zero (B) + Zero (C) + Zero (D) + Zero (E) + Zero (F) + Zero (G) + Zero (H) <= 2;
   end Valid_8;

   function Longest (Input : Input_Array) return Result is
   begin
      if Valid_8 (Input (1), Input (2), Input (3), Input (4), Input (5), Input (6), Input (7), Input (8)) then
         return 8;
      end if;
      if Valid_7 (Input (1), Input (2), Input (3), Input (4), Input (5), Input (6), Input (7)) then
         return 7;
      end if;
      if Valid_7 (Input (2), Input (3), Input (4), Input (5), Input (6), Input (7), Input (8)) then
         return 7;
      end if;
      if Valid_6 (Input (1), Input (2), Input (3), Input (4), Input (5), Input (6)) then
         return 6;
      end if;
      if Valid_6 (Input (2), Input (3), Input (4), Input (5), Input (6), Input (7)) then
         return 6;
      end if;
      if Valid_6 (Input (3), Input (4), Input (5), Input (6), Input (7), Input (8)) then
         return 6;
      end if;
      if Valid_5 (Input (1), Input (2), Input (3), Input (4), Input (5)) then
         return 5;
      end if;
      if Valid_5 (Input (2), Input (3), Input (4), Input (5), Input (6)) then
         return 5;
      end if;
      if Valid_5 (Input (3), Input (4), Input (5), Input (6), Input (7)) then
         return 5;
      end if;
      if Valid_5 (Input (4), Input (5), Input (6), Input (7), Input (8)) then
         return 5;
      end if;
      if Valid_4 (Input (1), Input (2), Input (3), Input (4)) then
         return 4;
      end if;
      if Valid_4 (Input (2), Input (3), Input (4), Input (5)) then
         return 4;
      end if;
      if Valid_4 (Input (3), Input (4), Input (5), Input (6)) then
         return 4;
      end if;
      if Valid_4 (Input (4), Input (5), Input (6), Input (7)) then
         return 4;
      end if;
      if Valid_4 (Input (5), Input (6), Input (7), Input (8)) then
         return 4;
      end if;
      if Valid_3 (Input (1), Input (2), Input (3)) then
         return 3;
      end if;
      if Valid_3 (Input (2), Input (3), Input (4)) then
         return 3;
      end if;
      if Valid_3 (Input (3), Input (4), Input (5)) then
         return 3;
      end if;
      if Valid_3 (Input (4), Input (5), Input (6)) then
         return 3;
      end if;
      if Valid_3 (Input (5), Input (6), Input (7)) then
         return 3;
      end if;
      if Valid_3 (Input (6), Input (7), Input (8)) then
         return 3;
      end if;
      if Valid_2 (Input (1), Input (2)) then
         return 2;
      end if;
      if Valid_2 (Input (2), Input (3)) then
         return 2;
      end if;
      if Valid_2 (Input (3), Input (4)) then
         return 2;
      end if;
      if Valid_2 (Input (4), Input (5)) then
         return 2;
      end if;
      if Valid_2 (Input (5), Input (6)) then
         return 2;
      end if;
      if Valid_2 (Input (6), Input (7)) then
         return 2;
      end if;
      if Valid_2 (Input (7), Input (8)) then
         return 2;
      end if;
      if Valid_1 (Input (1)) then
         return 1;
      end if;
      if Valid_1 (Input (2)) then
         return 1;
      end if;
      if Valid_1 (Input (3)) then
         return 1;
      end if;
      if Valid_1 (Input (4)) then
         return 1;
      end if;
      if Valid_1 (Input (5)) then
         return 1;
      end if;
      if Valid_1 (Input (6)) then
         return 1;
      end if;
      if Valid_1 (Input (7)) then
         return 1;
      end if;
      if Valid_1 (Input (8)) then
         return 1;
      end if;
      return 0;
   end Longest;
end Max_Consecutive_Ones_III;
