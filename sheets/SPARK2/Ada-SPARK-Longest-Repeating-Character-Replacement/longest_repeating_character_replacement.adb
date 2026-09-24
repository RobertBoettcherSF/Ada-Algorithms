pragma Ada_2022;

package body Longest_Repeating_Character_Replacement with SPARK_Mode => On is
   function Replaceable_3 (A : Character; B : Character; C : Character) return Boolean is
   begin
      return (B = A and then C = A) or else (C = A) or else (B = A) or else (C = B) or else (A = B and then C = B) or else (A = B) or else (B = C) or else (A = C) or else (A = C and then B = C);
   end Replaceable_3;

   function Replaceable_4 (A : Character; B : Character; C : Character; D : Character) return Boolean is
   begin
      return (B = A and then C = A and then D = A) or else (C = A and then D = A) or else (B = A and then D = A) or else (B = A and then C = A) or else (C = B and then D = B) or else (A = B and then C = B and then D = B) or else (A = B and then D = B) or else (A = B and then C = B) or else (B = C and then D = C) or else (A = C and then D = C) or else (A = C and then B = C and then D = C) or else (A = C and then B = C) or else (B = D and then C = D) or else (A = D and then C = D) or else (A = D and then B = D) or else (A = D and then B = D and then C = D);
   end Replaceable_4;

   function Replaceable_5 (A : Character; B : Character; C : Character; D : Character; E : Character) return Boolean is
   begin
      return (B = A and then C = A and then D = A and then E = A) or else (C = A and then D = A and then E = A) or else (B = A and then D = A and then E = A) or else (B = A and then C = A and then E = A) or else (B = A and then C = A and then D = A) or else (C = B and then D = B and then E = B) or else (A = B and then C = B and then D = B and then E = B) or else (A = B and then D = B and then E = B) or else (A = B and then C = B and then E = B) or else (A = B and then C = B and then D = B) or else (B = C and then D = C and then E = C) or else (A = C and then D = C and then E = C) or else (A = C and then B = C and then D = C and then E = C) or else (A = C and then B = C and then E = C) or else (A = C and then B = C and then D = C) or else (B = D and then C = D and then E = D) or else (A = D and then C = D and then E = D) or else (A = D and then B = D and then E = D) or else (A = D and then B = D and then C = D and then E = D) or else (A = D and then B = D and then C = D) or else (B = E and then C = E and then D = E) or else (A = E and then C = E and then D = E) or else (A = E and then B = E and then D = E) or else (A = E and then B = E and then C = E) or else (A = E and then B = E and then C = E and then D = E);
   end Replaceable_5;

   function Replaceable_6 (A : Character; B : Character; C : Character; D : Character; E : Character; F : Character) return Boolean is
   begin
      return (B = A and then C = A and then D = A and then E = A and then F = A) or else (C = A and then D = A and then E = A and then F = A) or else (B = A and then D = A and then E = A and then F = A) or else (B = A and then C = A and then E = A and then F = A) or else (B = A and then C = A and then D = A and then F = A) or else (B = A and then C = A and then D = A and then E = A) or else (C = B and then D = B and then E = B and then F = B) or else (A = B and then C = B and then D = B and then E = B and then F = B) or else (A = B and then D = B and then E = B and then F = B) or else (A = B and then C = B and then E = B and then F = B) or else (A = B and then C = B and then D = B and then F = B) or else (A = B and then C = B and then D = B and then E = B) or else (B = C and then D = C and then E = C and then F = C) or else (A = C and then D = C and then E = C and then F = C) or else (A = C and then B = C and then D = C and then E = C and then F = C) or else (A = C and then B = C and then E = C and then F = C) or else (A = C and then B = C and then D = C and then F = C) or else (A = C and then B = C and then D = C and then E = C) or else (B = D and then C = D and then E = D and then F = D) or else (A = D and then C = D and then E = D and then F = D) or else (A = D and then B = D and then E = D and then F = D) or else (A = D and then B = D and then C = D and then E = D and then F = D) or else (A = D and then B = D and then C = D and then F = D) or else (A = D and then B = D and then C = D and then E = D) or else (B = E and then C = E and then D = E and then F = E) or else (A = E and then C = E and then D = E and then F = E) or else (A = E and then B = E and then D = E and then F = E) or else (A = E and then B = E and then C = E and then F = E) or else (A = E and then B = E and then C = E and then D = E and then F = E) or else (A = E and then B = E and then C = E and then D = E) or else (B = F and then C = F and then D = F and then E = F) or else (A = F and then C = F and then D = F and then E = F) or else (A = F and then B = F and then D = F and then E = F) or else (A = F and then B = F and then C = F and then E = F) or else (A = F and then B = F and then C = F and then D = F) or else (A = F and then B = F and then C = F and then D = F and then E = F);
   end Replaceable_6;

   function Replaceable_7 (A : Character; B : Character; C : Character; D : Character; E : Character; F : Character; G : Character) return Boolean is
   begin
      return (B = A and then C = A and then D = A and then E = A and then F = A and then G = A) or else (C = A and then D = A and then E = A and then F = A and then G = A) or else (B = A and then D = A and then E = A and then F = A and then G = A) or else (B = A and then C = A and then E = A and then F = A and then G = A) or else (B = A and then C = A and then D = A and then F = A and then G = A) or else (B = A and then C = A and then D = A and then E = A and then G = A) or else (B = A and then C = A and then D = A and then E = A and then F = A) or else (C = B and then D = B and then E = B and then F = B and then G = B) or else (A = B and then C = B and then D = B and then E = B and then F = B and then G = B) or else (A = B and then D = B and then E = B and then F = B and then G = B) or else (A = B and then C = B and then E = B and then F = B and then G = B) or else (A = B and then C = B and then D = B and then F = B and then G = B) or else (A = B and then C = B and then D = B and then E = B and then G = B) or else (A = B and then C = B and then D = B and then E = B and then F = B) or else (B = C and then D = C and then E = C and then F = C and then G = C) or else (A = C and then D = C and then E = C and then F = C and then G = C) or else (A = C and then B = C and then D = C and then E = C and then F = C and then G = C) or else (A = C and then B = C and then E = C and then F = C and then G = C) or else (A = C and then B = C and then D = C and then F = C and then G = C) or else (A = C and then B = C and then D = C and then E = C and then G = C) or else (A = C and then B = C and then D = C and then E = C and then F = C) or else (B = D and then C = D and then E = D and then F = D and then G = D) or else (A = D and then C = D and then E = D and then F = D and then G = D) or else (A = D and then B = D and then E = D and then F = D and then G = D) or else (A = D and then B = D and then C = D and then E = D and then F = D and then G = D) or else (A = D and then B = D and then C = D and then F = D and then G = D) or else (A = D and then B = D and then C = D and then E = D and then G = D) or else (A = D and then B = D and then C = D and then E = D and then F = D) or else (B = E and then C = E and then D = E and then F = E and then G = E) or else (A = E and then C = E and then D = E and then F = E and then G = E) or else (A = E and then B = E and then D = E and then F = E and then G = E) or else (A = E and then B = E and then C = E and then F = E and then G = E) or else (A = E and then B = E and then C = E and then D = E and then F = E and then G = E) or else (A = E and then B = E and then C = E and then D = E and then G = E) or else (A = E and then B = E and then C = E and then D = E and then F = E) or else (B = F and then C = F and then D = F and then E = F and then G = F) or else (A = F and then C = F and then D = F and then E = F and then G = F) or else (A = F and then B = F and then D = F and then E = F and then G = F) or else (A = F and then B = F and then C = F and then E = F and then G = F) or else (A = F and then B = F and then C = F and then D = F and then G = F) or else (A = F and then B = F and then C = F and then D = F and then E = F and then G = F) or else (A = F and then B = F and then C = F and then D = F and then E = F) or else (B = G and then C = G and then D = G and then E = G and then F = G) or else (A = G and then C = G and then D = G and then E = G and then F = G) or else (A = G and then B = G and then D = G and then E = G and then F = G) or else (A = G and then B = G and then C = G and then E = G and then F = G) or else (A = G and then B = G and then C = G and then D = G and then F = G) or else (A = G and then B = G and then C = G and then D = G and then E = G) or else (A = G and then B = G and then C = G and then D = G and then E = G and then F = G);
   end Replaceable_7;

   function Replaceable_8 (A : Character; B : Character; C : Character; D : Character; E : Character; F : Character; G : Character; H : Character) return Boolean is
   begin
      return (B = A and then C = A and then D = A and then E = A and then F = A and then G = A and then H = A) or else (C = A and then D = A and then E = A and then F = A and then G = A and then H = A) or else (B = A and then D = A and then E = A and then F = A and then G = A and then H = A) or else (B = A and then C = A and then E = A and then F = A and then G = A and then H = A) or else (B = A and then C = A and then D = A and then F = A and then G = A and then H = A) or else (B = A and then C = A and then D = A and then E = A and then G = A and then H = A) or else (B = A and then C = A and then D = A and then E = A and then F = A and then H = A) or else (B = A and then C = A and then D = A and then E = A and then F = A and then G = A) or else (C = B and then D = B and then E = B and then F = B and then G = B and then H = B) or else (A = B and then C = B and then D = B and then E = B and then F = B and then G = B and then H = B) or else (A = B and then D = B and then E = B and then F = B and then G = B and then H = B) or else (A = B and then C = B and then E = B and then F = B and then G = B and then H = B) or else (A = B and then C = B and then D = B and then F = B and then G = B and then H = B) or else (A = B and then C = B and then D = B and then E = B and then G = B and then H = B) or else (A = B and then C = B and then D = B and then E = B and then F = B and then H = B) or else (A = B and then C = B and then D = B and then E = B and then F = B and then G = B) or else (B = C and then D = C and then E = C and then F = C and then G = C and then H = C) or else (A = C and then D = C and then E = C and then F = C and then G = C and then H = C) or else (A = C and then B = C and then D = C and then E = C and then F = C and then G = C and then H = C) or else (A = C and then B = C and then E = C and then F = C and then G = C and then H = C) or else (A = C and then B = C and then D = C and then F = C and then G = C and then H = C) or else (A = C and then B = C and then D = C and then E = C and then G = C and then H = C) or else (A = C and then B = C and then D = C and then E = C and then F = C and then H = C) or else (A = C and then B = C and then D = C and then E = C and then F = C and then G = C) or else (B = D and then C = D and then E = D and then F = D and then G = D and then H = D) or else (A = D and then C = D and then E = D and then F = D and then G = D and then H = D) or else (A = D and then B = D and then E = D and then F = D and then G = D and then H = D) or else (A = D and then B = D and then C = D and then E = D and then F = D and then G = D and then H = D) or else (A = D and then B = D and then C = D and then F = D and then G = D and then H = D) or else (A = D and then B = D and then C = D and then E = D and then G = D and then H = D) or else (A = D and then B = D and then C = D and then E = D and then F = D and then H = D) or else (A = D and then B = D and then C = D and then E = D and then F = D and then G = D) or else (B = E and then C = E and then D = E and then F = E and then G = E and then H = E) or else (A = E and then C = E and then D = E and then F = E and then G = E and then H = E) or else (A = E and then B = E and then D = E and then F = E and then G = E and then H = E) or else (A = E and then B = E and then C = E and then F = E and then G = E and then H = E) or else (A = E and then B = E and then C = E and then D = E and then F = E and then G = E and then H = E) or else (A = E and then B = E and then C = E and then D = E and then G = E and then H = E) or else (A = E and then B = E and then C = E and then D = E and then F = E and then H = E) or else (A = E and then B = E and then C = E and then D = E and then F = E and then G = E) or else (B = F and then C = F and then D = F and then E = F and then G = F and then H = F) or else (A = F and then C = F and then D = F and then E = F and then G = F and then H = F) or else (A = F and then B = F and then D = F and then E = F and then G = F and then H = F) or else (A = F and then B = F and then C = F and then E = F and then G = F and then H = F) or else (A = F and then B = F and then C = F and then D = F and then G = F and then H = F) or else (A = F and then B = F and then C = F and then D = F and then E = F and then G = F and then H = F) or else (A = F and then B = F and then C = F and then D = F and then E = F and then H = F) or else (A = F and then B = F and then C = F and then D = F and then E = F and then G = F) or else (B = G and then C = G and then D = G and then E = G and then F = G and then H = G) or else (A = G and then C = G and then D = G and then E = G and then F = G and then H = G) or else (A = G and then B = G and then D = G and then E = G and then F = G and then H = G) or else (A = G and then B = G and then C = G and then E = G and then F = G and then H = G) or else (A = G and then B = G and then C = G and then D = G and then F = G and then H = G) or else (A = G and then B = G and then C = G and then D = G and then E = G and then H = G) or else (A = G and then B = G and then C = G and then D = G and then E = G and then F = G and then H = G) or else (A = G and then B = G and then C = G and then D = G and then E = G and then F = G) or else (B = H and then C = H and then D = H and then E = H and then F = H and then G = H) or else (A = H and then C = H and then D = H and then E = H and then F = H and then G = H) or else (A = H and then B = H and then D = H and then E = H and then F = H and then G = H) or else (A = H and then B = H and then C = H and then E = H and then F = H and then G = H) or else (A = H and then B = H and then C = H and then D = H and then F = H and then G = H) or else (A = H and then B = H and then C = H and then D = H and then E = H and then G = H) or else (A = H and then B = H and then C = H and then D = H and then E = H and then F = H) or else (A = H and then B = H and then C = H and then D = H and then E = H and then F = H and then G = H);
   end Replaceable_8;

   function Longest (Input : Text_Array) return Result is
   begin
      if Replaceable_8 (Input (1), Input (2), Input (3), Input (4), Input (5), Input (6), Input (7), Input (8)) then
         return 8;
      end if;
      if Replaceable_7 (Input (1), Input (2), Input (3), Input (4), Input (5), Input (6), Input (7)) then
         return 7;
      end if;
      if Replaceable_7 (Input (2), Input (3), Input (4), Input (5), Input (6), Input (7), Input (8)) then
         return 7;
      end if;
      if Replaceable_6 (Input (1), Input (2), Input (3), Input (4), Input (5), Input (6)) then
         return 6;
      end if;
      if Replaceable_6 (Input (2), Input (3), Input (4), Input (5), Input (6), Input (7)) then
         return 6;
      end if;
      if Replaceable_6 (Input (3), Input (4), Input (5), Input (6), Input (7), Input (8)) then
         return 6;
      end if;
      if Replaceable_5 (Input (1), Input (2), Input (3), Input (4), Input (5)) then
         return 5;
      end if;
      if Replaceable_5 (Input (2), Input (3), Input (4), Input (5), Input (6)) then
         return 5;
      end if;
      if Replaceable_5 (Input (3), Input (4), Input (5), Input (6), Input (7)) then
         return 5;
      end if;
      if Replaceable_5 (Input (4), Input (5), Input (6), Input (7), Input (8)) then
         return 5;
      end if;
      if Replaceable_4 (Input (1), Input (2), Input (3), Input (4)) then
         return 4;
      end if;
      if Replaceable_4 (Input (2), Input (3), Input (4), Input (5)) then
         return 4;
      end if;
      if Replaceable_4 (Input (3), Input (4), Input (5), Input (6)) then
         return 4;
      end if;
      if Replaceable_4 (Input (4), Input (5), Input (6), Input (7)) then
         return 4;
      end if;
      if Replaceable_4 (Input (5), Input (6), Input (7), Input (8)) then
         return 4;
      end if;
      if Replaceable_3 (Input (1), Input (2), Input (3)) then
         return 3;
      end if;
      if Replaceable_3 (Input (2), Input (3), Input (4)) then
         return 3;
      end if;
      if Replaceable_3 (Input (3), Input (4), Input (5)) then
         return 3;
      end if;
      if Replaceable_3 (Input (4), Input (5), Input (6)) then
         return 3;
      end if;
      if Replaceable_3 (Input (5), Input (6), Input (7)) then
         return 3;
      end if;
      if Replaceable_3 (Input (6), Input (7), Input (8)) then
         return 3;
      end if;
      return 2;
   end Longest;
end Longest_Repeating_Character_Replacement;
