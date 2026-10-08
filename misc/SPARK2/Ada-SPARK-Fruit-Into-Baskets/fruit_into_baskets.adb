pragma Ada_2022;

package body Fruit_Into_Baskets with SPARK_Mode => On is
   function Two_Types_3 (A : Fruit; B : Fruit; C : Fruit) return Boolean is
   begin
      return ((C = A or else C = B)) or else ((B = A or else B = C)) or else ((A = B or else A = C));
   end Two_Types_3;

   function Two_Types_4 (A : Fruit; B : Fruit; C : Fruit; D : Fruit) return Boolean is
   begin
      return ((C = A or else C = B) and then (D = A or else D = B)) or else ((B = A or else B = C) and then (D = A or else D = C)) or else ((B = A or else B = D) and then (C = A or else C = D)) or else ((A = B or else A = C) and then (D = B or else D = C)) or else ((A = B or else A = D) and then (C = B or else C = D)) or else ((A = C or else A = D) and then (B = C or else B = D));
   end Two_Types_4;

   function Two_Types_5 (A : Fruit; B : Fruit; C : Fruit; D : Fruit; E : Fruit) return Boolean is
   begin
      return ((C = A or else C = B) and then (D = A or else D = B) and then (E = A or else E = B)) or else ((B = A or else B = C) and then (D = A or else D = C) and then (E = A or else E = C)) or else ((B = A or else B = D) and then (C = A or else C = D) and then (E = A or else E = D)) or else ((B = A or else B = E) and then (C = A or else C = E) and then (D = A or else D = E)) or else ((A = B or else A = C) and then (D = B or else D = C) and then (E = B or else E = C)) or else ((A = B or else A = D) and then (C = B or else C = D) and then (E = B or else E = D)) or else ((A = B or else A = E) and then (C = B or else C = E) and then (D = B or else D = E)) or else ((A = C or else A = D) and then (B = C or else B = D) and then (E = C or else E = D)) or else ((A = C or else A = E) and then (B = C or else B = E) and then (D = C or else D = E)) or else ((A = D or else A = E) and then (B = D or else B = E) and then (C = D or else C = E));
   end Two_Types_5;

   function Two_Types_6 (A : Fruit; B : Fruit; C : Fruit; D : Fruit; E : Fruit; F : Fruit) return Boolean is
   begin
      return ((C = A or else C = B) and then (D = A or else D = B) and then (E = A or else E = B) and then (F = A or else F = B)) or else ((B = A or else B = C) and then (D = A or else D = C) and then (E = A or else E = C) and then (F = A or else F = C)) or else ((B = A or else B = D) and then (C = A or else C = D) and then (E = A or else E = D) and then (F = A or else F = D)) or else ((B = A or else B = E) and then (C = A or else C = E) and then (D = A or else D = E) and then (F = A or else F = E)) or else ((B = A or else B = F) and then (C = A or else C = F) and then (D = A or else D = F) and then (E = A or else E = F)) or else ((A = B or else A = C) and then (D = B or else D = C) and then (E = B or else E = C) and then (F = B or else F = C)) or else ((A = B or else A = D) and then (C = B or else C = D) and then (E = B or else E = D) and then (F = B or else F = D)) or else ((A = B or else A = E) and then (C = B or else C = E) and then (D = B or else D = E) and then (F = B or else F = E)) or else ((A = B or else A = F) and then (C = B or else C = F) and then (D = B or else D = F) and then (E = B or else E = F)) or else ((A = C or else A = D) and then (B = C or else B = D) and then (E = C or else E = D) and then (F = C or else F = D)) or else ((A = C or else A = E) and then (B = C or else B = E) and then (D = C or else D = E) and then (F = C or else F = E)) or else ((A = C or else A = F) and then (B = C or else B = F) and then (D = C or else D = F) and then (E = C or else E = F)) or else ((A = D or else A = E) and then (B = D or else B = E) and then (C = D or else C = E) and then (F = D or else F = E)) or else ((A = D or else A = F) and then (B = D or else B = F) and then (C = D or else C = F) and then (E = D or else E = F)) or else ((A = E or else A = F) and then (B = E or else B = F) and then (C = E or else C = F) and then (D = E or else D = F));
   end Two_Types_6;

   function Two_Types_7 (A : Fruit; B : Fruit; C : Fruit; D : Fruit; E : Fruit; F : Fruit; G : Fruit) return Boolean is
   begin
      return ((C = A or else C = B) and then (D = A or else D = B) and then (E = A or else E = B) and then (F = A or else F = B) and then (G = A or else G = B)) or else ((B = A or else B = C) and then (D = A or else D = C) and then (E = A or else E = C) and then (F = A or else F = C) and then (G = A or else G = C)) or else ((B = A or else B = D) and then (C = A or else C = D) and then (E = A or else E = D) and then (F = A or else F = D) and then (G = A or else G = D)) or else ((B = A or else B = E) and then (C = A or else C = E) and then (D = A or else D = E) and then (F = A or else F = E) and then (G = A or else G = E)) or else ((B = A or else B = F) and then (C = A or else C = F) and then (D = A or else D = F) and then (E = A or else E = F) and then (G = A or else G = F)) or else ((B = A or else B = G) and then (C = A or else C = G) and then (D = A or else D = G) and then (E = A or else E = G) and then (F = A or else F = G)) or else ((A = B or else A = C) and then (D = B or else D = C) and then (E = B or else E = C) and then (F = B or else F = C) and then (G = B or else G = C)) or else ((A = B or else A = D) and then (C = B or else C = D) and then (E = B or else E = D) and then (F = B or else F = D) and then (G = B or else G = D)) or else ((A = B or else A = E) and then (C = B or else C = E) and then (D = B or else D = E) and then (F = B or else F = E) and then (G = B or else G = E)) or else ((A = B or else A = F) and then (C = B or else C = F) and then (D = B or else D = F) and then (E = B or else E = F) and then (G = B or else G = F)) or else ((A = B or else A = G) and then (C = B or else C = G) and then (D = B or else D = G) and then (E = B or else E = G) and then (F = B or else F = G)) or else ((A = C or else A = D) and then (B = C or else B = D) and then (E = C or else E = D) and then (F = C or else F = D) and then (G = C or else G = D)) or else ((A = C or else A = E) and then (B = C or else B = E) and then (D = C or else D = E) and then (F = C or else F = E) and then (G = C or else G = E)) or else ((A = C or else A = F) and then (B = C or else B = F) and then (D = C or else D = F) and then (E = C or else E = F) and then (G = C or else G = F)) or else ((A = C or else A = G) and then (B = C or else B = G) and then (D = C or else D = G) and then (E = C or else E = G) and then (F = C or else F = G)) or else ((A = D or else A = E) and then (B = D or else B = E) and then (C = D or else C = E) and then (F = D or else F = E) and then (G = D or else G = E)) or else ((A = D or else A = F) and then (B = D or else B = F) and then (C = D or else C = F) and then (E = D or else E = F) and then (G = D or else G = F)) or else ((A = D or else A = G) and then (B = D or else B = G) and then (C = D or else C = G) and then (E = D or else E = G) and then (F = D or else F = G)) or else ((A = E or else A = F) and then (B = E or else B = F) and then (C = E or else C = F) and then (D = E or else D = F) and then (G = E or else G = F)) or else ((A = E or else A = G) and then (B = E or else B = G) and then (C = E or else C = G) and then (D = E or else D = G) and then (F = E or else F = G)) or else ((A = F or else A = G) and then (B = F or else B = G) and then (C = F or else C = G) and then (D = F or else D = G) and then (E = F or else E = G));
   end Two_Types_7;

   function Two_Types_8 (A : Fruit; B : Fruit; C : Fruit; D : Fruit; E : Fruit; F : Fruit; G : Fruit; H : Fruit) return Boolean is
   begin
      return ((C = A or else C = B) and then (D = A or else D = B) and then (E = A or else E = B) and then (F = A or else F = B) and then (G = A or else G = B) and then (H = A or else H = B)) or else ((B = A or else B = C) and then (D = A or else D = C) and then (E = A or else E = C) and then (F = A or else F = C) and then (G = A or else G = C) and then (H = A or else H = C)) or else ((B = A or else B = D) and then (C = A or else C = D) and then (E = A or else E = D) and then (F = A or else F = D) and then (G = A or else G = D) and then (H = A or else H = D)) or else ((B = A or else B = E) and then (C = A or else C = E) and then (D = A or else D = E) and then (F = A or else F = E) and then (G = A or else G = E) and then (H = A or else H = E)) or else ((B = A or else B = F) and then (C = A or else C = F) and then (D = A or else D = F) and then (E = A or else E = F) and then (G = A or else G = F) and then (H = A or else H = F)) or else ((B = A or else B = G) and then (C = A or else C = G) and then (D = A or else D = G) and then (E = A or else E = G) and then (F = A or else F = G) and then (H = A or else H = G)) or else ((B = A or else B = H) and then (C = A or else C = H) and then (D = A or else D = H) and then (E = A or else E = H) and then (F = A or else F = H) and then (G = A or else G = H)) or else ((A = B or else A = C) and then (D = B or else D = C) and then (E = B or else E = C) and then (F = B or else F = C) and then (G = B or else G = C) and then (H = B or else H = C)) or else ((A = B or else A = D) and then (C = B or else C = D) and then (E = B or else E = D) and then (F = B or else F = D) and then (G = B or else G = D) and then (H = B or else H = D)) or else ((A = B or else A = E) and then (C = B or else C = E) and then (D = B or else D = E) and then (F = B or else F = E) and then (G = B or else G = E) and then (H = B or else H = E)) or else ((A = B or else A = F) and then (C = B or else C = F) and then (D = B or else D = F) and then (E = B or else E = F) and then (G = B or else G = F) and then (H = B or else H = F)) or else ((A = B or else A = G) and then (C = B or else C = G) and then (D = B or else D = G) and then (E = B or else E = G) and then (F = B or else F = G) and then (H = B or else H = G)) or else ((A = B or else A = H) and then (C = B or else C = H) and then (D = B or else D = H) and then (E = B or else E = H) and then (F = B or else F = H) and then (G = B or else G = H)) or else ((A = C or else A = D) and then (B = C or else B = D) and then (E = C or else E = D) and then (F = C or else F = D) and then (G = C or else G = D) and then (H = C or else H = D)) or else ((A = C or else A = E) and then (B = C or else B = E) and then (D = C or else D = E) and then (F = C or else F = E) and then (G = C or else G = E) and then (H = C or else H = E)) or else ((A = C or else A = F) and then (B = C or else B = F) and then (D = C or else D = F) and then (E = C or else E = F) and then (G = C or else G = F) and then (H = C or else H = F)) or else ((A = C or else A = G) and then (B = C or else B = G) and then (D = C or else D = G) and then (E = C or else E = G) and then (F = C or else F = G) and then (H = C or else H = G)) or else ((A = C or else A = H) and then (B = C or else B = H) and then (D = C or else D = H) and then (E = C or else E = H) and then (F = C or else F = H) and then (G = C or else G = H)) or else ((A = D or else A = E) and then (B = D or else B = E) and then (C = D or else C = E) and then (F = D or else F = E) and then (G = D or else G = E) and then (H = D or else H = E)) or else ((A = D or else A = F) and then (B = D or else B = F) and then (C = D or else C = F) and then (E = D or else E = F) and then (G = D or else G = F) and then (H = D or else H = F)) or else ((A = D or else A = G) and then (B = D or else B = G) and then (C = D or else C = G) and then (E = D or else E = G) and then (F = D or else F = G) and then (H = D or else H = G)) or else ((A = D or else A = H) and then (B = D or else B = H) and then (C = D or else C = H) and then (E = D or else E = H) and then (F = D or else F = H) and then (G = D or else G = H)) or else ((A = E or else A = F) and then (B = E or else B = F) and then (C = E or else C = F) and then (D = E or else D = F) and then (G = E or else G = F) and then (H = E or else H = F)) or else ((A = E or else A = G) and then (B = E or else B = G) and then (C = E or else C = G) and then (D = E or else D = G) and then (F = E or else F = G) and then (H = E or else H = G)) or else ((A = E or else A = H) and then (B = E or else B = H) and then (C = E or else C = H) and then (D = E or else D = H) and then (F = E or else F = H) and then (G = E or else G = H)) or else ((A = F or else A = G) and then (B = F or else B = G) and then (C = F or else C = G) and then (D = F or else D = G) and then (E = F or else E = G) and then (H = F or else H = G)) or else ((A = F or else A = H) and then (B = F or else B = H) and then (C = F or else C = H) and then (D = F or else D = H) and then (E = F or else E = H) and then (G = F or else G = H)) or else ((A = G or else A = H) and then (B = G or else B = H) and then (C = G or else C = H) and then (D = G or else D = H) and then (E = G or else E = H) and then (F = G or else F = H));
   end Two_Types_8;

   function Maximum (Input : Input_Array) return Result is
   begin
      if Two_Types_8 (Input (1), Input (2), Input (3), Input (4), Input (5), Input (6), Input (7), Input (8)) then
         return 8;
      end if;
      if Two_Types_7 (Input (1), Input (2), Input (3), Input (4), Input (5), Input (6), Input (7)) then
         return 7;
      end if;
      if Two_Types_7 (Input (2), Input (3), Input (4), Input (5), Input (6), Input (7), Input (8)) then
         return 7;
      end if;
      if Two_Types_6 (Input (1), Input (2), Input (3), Input (4), Input (5), Input (6)) then
         return 6;
      end if;
      if Two_Types_6 (Input (2), Input (3), Input (4), Input (5), Input (6), Input (7)) then
         return 6;
      end if;
      if Two_Types_6 (Input (3), Input (4), Input (5), Input (6), Input (7), Input (8)) then
         return 6;
      end if;
      if Two_Types_5 (Input (1), Input (2), Input (3), Input (4), Input (5)) then
         return 5;
      end if;
      if Two_Types_5 (Input (2), Input (3), Input (4), Input (5), Input (6)) then
         return 5;
      end if;
      if Two_Types_5 (Input (3), Input (4), Input (5), Input (6), Input (7)) then
         return 5;
      end if;
      if Two_Types_5 (Input (4), Input (5), Input (6), Input (7), Input (8)) then
         return 5;
      end if;
      if Two_Types_4 (Input (1), Input (2), Input (3), Input (4)) then
         return 4;
      end if;
      if Two_Types_4 (Input (2), Input (3), Input (4), Input (5)) then
         return 4;
      end if;
      if Two_Types_4 (Input (3), Input (4), Input (5), Input (6)) then
         return 4;
      end if;
      if Two_Types_4 (Input (4), Input (5), Input (6), Input (7)) then
         return 4;
      end if;
      if Two_Types_4 (Input (5), Input (6), Input (7), Input (8)) then
         return 4;
      end if;
      if Two_Types_3 (Input (1), Input (2), Input (3)) then
         return 3;
      end if;
      if Two_Types_3 (Input (2), Input (3), Input (4)) then
         return 3;
      end if;
      if Two_Types_3 (Input (3), Input (4), Input (5)) then
         return 3;
      end if;
      if Two_Types_3 (Input (4), Input (5), Input (6)) then
         return 3;
      end if;
      if Two_Types_3 (Input (5), Input (6), Input (7)) then
         return 3;
      end if;
      if Two_Types_3 (Input (6), Input (7), Input (8)) then
         return 3;
      end if;
      return 2;
   end Maximum;
end Fruit_Into_Baskets;
