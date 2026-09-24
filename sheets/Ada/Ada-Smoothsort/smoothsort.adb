--  Smoothsort body — Dijkstra's algorithm after EWD796a / Wikibooks Delphi.
--  Indices are relative offsets 0 .. N-1 mapped onto A'First .. A'Last.
--  Stretch sizes are consecutive Leonardo numbers maintained by Up/Down;
--  the bit-string P encodes the standard concatenation of stretches.
--  B/C are signed Integers because Down may briefly produce C = -1 when B = 1.

pragma Ada_2022;

with Interfaces; use Interfaces;

package body Smoothsort
  with SPARK_Mode => Off
is

   --  Precomputed Leonardo numbers L(0) .. L(40) (OEIS A001595).
   Leonardo_Table : constant array (0 .. Max_Leonardo_Order) of Natural :=
     [0  => 1,
      1  => 1,
      2  => 3,
      3  => 5,
      4  => 9,
      5  => 15,
      6  => 25,
      7  => 41,
      8  => 67,
      9  => 109,
      10 => 177,
      11 => 287,
      12 => 465,
      13 => 753,
      14 => 1219,
      15 => 1973,
      16 => 3193,
      17 => 5167,
      18 => 8361,
      19 => 13_529,
      20 => 21_891,
      21 => 35_421,
      22 => 57_313,
      23 => 92_735,
      24 => 150_049,
      25 => 242_785,
      26 => 392_835,
      27 => 635_621,
      28 => 1_028_457,
      29 => 1_664_079,
      30 => 2_692_537,
      31 => 4_356_617,
      32 => 7_049_155,
      33 => 11_405_773,
      34 => 18_454_929,
      35 => 29_860_703,
      36 => 48_315_633,
      37 => 78_176_337,
      38 => 126_491_971,
      39 => 204_668_309,
      40 => 331_160_281];

   function Leonardo (K : Natural) return Natural is
   begin
      if K > Max_Leonardo_Order then
         raise Invalid_Argument;
      end if;
      return Leonardo_Table (K);
   end Leonardo;

   function Is_Sorted (A : Element_Array) return Boolean is
   begin
      if A'Length <= 1 then
         return True;
      end if;
      for I in A'First .. A'Last - 1 loop
         if A (I) > A (I + 1) then
            return False;
         end if;
      end loop;
      return True;
   end Is_Sorted;

   procedure Sort (A : in out Element_Array) is
      N : constant Integer := Integer (A'Length);

      --  Relative offset Off maps to A (A'First + Off); Off is always in
      --  0 .. N-1 when the algorithm invariants hold.
      function At_Offset (Off : Integer) return Integer is
        (A (A'First + Off))
        with Inline;

      procedure Set_Offset (Off : Integer; V : Integer)
        with Inline
      is
      begin
         A (A'First + Off) := V;
      end Set_Offset;

      --  Dijkstra stretch bookkeeping (EWD796a / Delphi reference).
      Q, R, B, C, R1, B1, C1 : Integer;
      P                     : Unsigned_64;

      procedure Up (Vb, Vc : in out Integer)
        with Inline
      is
         Tmp : constant Integer := Vb;
      begin
         Vb := Vb + Vc + 1;
         Vc := Tmp;
      end Up;

      procedure Down (Vb, Vc : in out Integer)
        with Inline
      is
         Tmp : constant Integer := Vc;
      begin
         Vc := Vb - Vc - 1;
         Vb := Tmp;
      end Down;

      procedure Sift is
         R0  : constant Integer := R1;
         Tmp : constant Integer := At_Offset (R0);
         R2  : Integer;
      begin
         while B1 >= 3 loop
            R2 := R1 - B1 + C1;
            if At_Offset (R1 - 1) >= At_Offset (R2) then
               R2 := R1 - 1;
               Down (B1, C1);
            end if;
            if At_Offset (R2) < Tmp then
               B1 := 1;
            else
               Set_Offset (R1, At_Offset (R2));
               R1 := R2;
               Down (B1, C1);
            end if;
         end loop;
         if R1 /= R0 then
            Set_Offset (R1, Tmp);
         end if;
      end Sift;

      procedure Trinkle is
         P1     : Unsigned_64 := P;
         R0     : constant Integer := R1;
         Tmp    : constant Integer := At_Offset (R0);
         R2, R3 : Integer;
      begin
         B1 := B;
         C1 := C;

         while P1 > 0 loop
            while (P1 and 1) = 0 loop
               P1 := Shift_Right (P1, 1);
               Up (B1, C1);
            end loop;

            --  P1 = 1 => no stepson; avoid R1 - B1 when it would be -1.
            if P1 = 1 then
               P1 := 0;
            else
               R3 := R1 - B1;
               if At_Offset (R3) < Tmp then
                  P1 := 0;
               else
                  P1 := P1 - 1;
                  if B1 = 1 then
                     Set_Offset (R1, At_Offset (R3));
                     R1 := R3;
                  elsif B1 >= 3 then
                     R2 := R1 - B1 + C1;
                     if At_Offset (R1 - 1) >= At_Offset (R2) then
                        R2 := R1 - 1;
                        Down (B1, C1);
                        P1 := Shift_Left (P1, 1);
                     end if;
                     if At_Offset (R2) < At_Offset (R3) then
                        Set_Offset (R1, At_Offset (R3));
                        R1 := R3;
                     else
                        Set_Offset (R1, At_Offset (R2));
                        R1 := R2;
                        Down (B1, C1);
                        P1 := 0;
                     end if;
                  end if;
               end if;
            end if;
         end loop;

         if R1 /= R0 then
            Set_Offset (R1, Tmp);
         end if;
         Sift;
      end Trinkle;

      procedure Semitrinkle is
         Tmp : Integer;
      begin
         R1 := R - C;
         if At_Offset (R1) > At_Offset (R) then
            Tmp := At_Offset (R);
            Set_Offset (R, At_Offset (R1));
            Set_Offset (R1, Tmp);
            Trinkle;
         end if;
      end Semitrinkle;

   begin
      if A'Length > Max_Length then
         raise Invalid_Argument;
      end if;
      if N <= 1 then
         return;
      end if;

      Q := 1;
      R := 0;
      P := 1;
      B := 1;
      C := 1;

      while Q < N loop
         R1 := R;
         if (P and 7) = 3 then
            B1 := B;
            C1 := C;
            Sift;
            P := Shift_Right (P + 1, 2);
            Up (B, C);
            Up (B, C);
         elsif (P and 3) = 1 then
            if Q + C < N then
               B1 := B;
               C1 := C;
               Sift;
            else
               Trinkle;
            end if;
            loop
               Down (B, C);
               P := Shift_Left (P, 1);
               exit when B <= 1;
            end loop;
            P := P + 1;
         end if;
         Q := Q + 1;
         R := R + 1;
      end loop;

      R1 := R;
      Trinkle;

      while Q > 1 loop
         Q := Q - 1;
         if B = 1 then
            R := R - 1;
            P := P - 1;
            while (P and 1) = 0 loop
               P := Shift_Right (P, 1);
               Up (B, C);
            end loop;
         elsif B >= 3 then
            P := P - 1;
            R := R - B + C;
            if P > 0 then
               Semitrinkle;
            end if;
            Down (B, C);
            P := Shift_Left (P, 1) + 1;
            R := R + C;
            Semitrinkle;
            Down (B, C);
            P := Shift_Left (P, 1) + 1;
         end if;
      end loop;
   end Sort;

end Smoothsort;
