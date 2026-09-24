pragma Ada_2022;

package body Longest_Substring_Without_Repeating with SPARK_Mode => On is
   function Unique_2 (A : Character; B : Character) return Boolean is
   begin
      return A /= B;
   end Unique_2;

   function Unique_3 (A : Character; B : Character; C : Character) return Boolean is
   begin
      return A /= B and then A /= C and then B /= C;
   end Unique_3;

   function Unique_4 (A : Character; B : Character; C : Character; D : Character) return Boolean is
   begin
      return A /= B and then A /= C and then A /= D and then B /= C and then B /= D and then C /= D;
   end Unique_4;

   function Unique_5 (A : Character; B : Character; C : Character; D : Character; E : Character) return Boolean is
   begin
      return A /= B and then A /= C and then A /= D and then A /= E and then B /= C and then B /= D and then B /= E and then C /= D and then C /= E and then D /= E;
   end Unique_5;

   function Unique_6 (A : Character; B : Character; C : Character; D : Character; E : Character; F : Character) return Boolean is
   begin
      return A /= B and then A /= C and then A /= D and then A /= E and then A /= F and then B /= C and then B /= D and then B /= E and then B /= F and then C /= D and then C /= E and then C /= F and then D /= E and then D /= F and then E /= F;
   end Unique_6;

   function Unique_7 (A : Character; B : Character; C : Character; D : Character; E : Character; F : Character; G : Character) return Boolean is
   begin
      return A /= B and then A /= C and then A /= D and then A /= E and then A /= F and then A /= G and then B /= C and then B /= D and then B /= E and then B /= F and then B /= G and then C /= D and then C /= E and then C /= F and then C /= G and then D /= E and then D /= F and then D /= G and then E /= F and then E /= G and then F /= G;
   end Unique_7;

   function Unique_8 (A : Character; B : Character; C : Character; D : Character; E : Character; F : Character; G : Character; H : Character) return Boolean is
   begin
      return A /= B and then A /= C and then A /= D and then A /= E and then A /= F and then A /= G and then A /= H and then B /= C and then B /= D and then B /= E and then B /= F and then B /= G and then B /= H and then C /= D and then C /= E and then C /= F and then C /= G and then C /= H and then D /= E and then D /= F and then D /= G and then D /= H and then E /= F and then E /= G and then E /= H and then F /= G and then F /= H and then G /= H;
   end Unique_8;

   function Longest (Input : Text_Array) return Result is
   begin
      if Unique_8 (Input (1), Input (2), Input (3), Input (4), Input (5), Input (6), Input (7), Input (8)) then
         return 8;
      end if;
      if Unique_7 (Input (1), Input (2), Input (3), Input (4), Input (5), Input (6), Input (7)) then
         return 7;
      end if;
      if Unique_7 (Input (2), Input (3), Input (4), Input (5), Input (6), Input (7), Input (8)) then
         return 7;
      end if;
      if Unique_6 (Input (1), Input (2), Input (3), Input (4), Input (5), Input (6)) then
         return 6;
      end if;
      if Unique_6 (Input (2), Input (3), Input (4), Input (5), Input (6), Input (7)) then
         return 6;
      end if;
      if Unique_6 (Input (3), Input (4), Input (5), Input (6), Input (7), Input (8)) then
         return 6;
      end if;
      if Unique_5 (Input (1), Input (2), Input (3), Input (4), Input (5)) then
         return 5;
      end if;
      if Unique_5 (Input (2), Input (3), Input (4), Input (5), Input (6)) then
         return 5;
      end if;
      if Unique_5 (Input (3), Input (4), Input (5), Input (6), Input (7)) then
         return 5;
      end if;
      if Unique_5 (Input (4), Input (5), Input (6), Input (7), Input (8)) then
         return 5;
      end if;
      if Unique_4 (Input (1), Input (2), Input (3), Input (4)) then
         return 4;
      end if;
      if Unique_4 (Input (2), Input (3), Input (4), Input (5)) then
         return 4;
      end if;
      if Unique_4 (Input (3), Input (4), Input (5), Input (6)) then
         return 4;
      end if;
      if Unique_4 (Input (4), Input (5), Input (6), Input (7)) then
         return 4;
      end if;
      if Unique_4 (Input (5), Input (6), Input (7), Input (8)) then
         return 4;
      end if;
      if Unique_3 (Input (1), Input (2), Input (3)) then
         return 3;
      end if;
      if Unique_3 (Input (2), Input (3), Input (4)) then
         return 3;
      end if;
      if Unique_3 (Input (3), Input (4), Input (5)) then
         return 3;
      end if;
      if Unique_3 (Input (4), Input (5), Input (6)) then
         return 3;
      end if;
      if Unique_3 (Input (5), Input (6), Input (7)) then
         return 3;
      end if;
      if Unique_3 (Input (6), Input (7), Input (8)) then
         return 3;
      end if;
      if Unique_2 (Input (1), Input (2)) then
         return 2;
      end if;
      if Unique_2 (Input (2), Input (3)) then
         return 2;
      end if;
      if Unique_2 (Input (3), Input (4)) then
         return 2;
      end if;
      if Unique_2 (Input (4), Input (5)) then
         return 2;
      end if;
      if Unique_2 (Input (5), Input (6)) then
         return 2;
      end if;
      if Unique_2 (Input (6), Input (7)) then
         return 2;
      end if;
      if Unique_2 (Input (7), Input (8)) then
         return 2;
      end if;
      return 1;
   end Longest;
end Longest_Substring_Without_Repeating;
