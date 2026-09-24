--  Euclidean_Distance_Transform body — exact naive + Meijster EDT and
--  3-4 chamfer approximation on educational binary grids.

pragma Ada_2022;

with Ada.Numerics.Long_Elementary_Functions;

package body Euclidean_Distance_Transform
  with SPARK_Mode => Off
is

   package Math renames Ada.Numerics.Long_Elementary_Functions;

   ---------------------------------------------------------------------------
   -- Validation
   ---------------------------------------------------------------------------

   procedure Require_Valid_Image (Image : Binary_Image) is
   begin
      if Image'Length (1) = 0 or else Image'Length (2) = 0 then
         raise Invalid_Argument;
      end if;
      if Image'Length (1) > Max_Height or else Image'Length (2) > Max_Width then
         raise Invalid_Argument;
      end if;
      if not Has_Feature (Image) then
         raise Invalid_Argument;
      end if;
   end Require_Valid_Image;

   ---------------------------------------------------------------------------
   -- Numeric helpers
   ---------------------------------------------------------------------------

   function Near (A, B : Real; Tol : Real := Epsilon) return Boolean is
   begin
      return abs (A - B) <= Tol;
   end Near;

   function Has_Feature (Image : Binary_Image) return Boolean is
   begin
      for R in Image'Range (1) loop
         for C in Image'Range (2) loop
            if Image (R, C) then
               return True;
            end if;
         end loop;
      end loop;
      return False;
   end Has_Feature;

   function Feature_Count (Image : Binary_Image) return Natural is
      N : Natural := 0;
   begin
      for R in Image'Range (1) loop
         for C in Image'Range (2) loop
            if Image (R, C) then
               N := N + 1;
            end if;
         end loop;
      end loop;
      return N;
   end Feature_Count;

   function Width_Of (Image : Binary_Image) return Width_Count is
   begin
      return Image'Length (2);
   end Width_Of;

   function Height_Of (Image : Binary_Image) return Height_Count is
   begin
      return Image'Length (1);
   end Height_Of;

   ---------------------------------------------------------------------------
   -- Exact naive squared EDT
   ---------------------------------------------------------------------------

   function Squared_Distance_Transform
     (Image : Binary_Image) return Squared_Distance_Map
   is
      Result : Squared_Distance_Map (Image'Range (1), Image'Range (2));
      Best   : Natural;
      Dr, Dc : Integer;
      Cand   : Natural;
      Inf    : constant Natural :=
        Max_Height * Max_Height + Max_Width * Max_Width;
   begin
      Require_Valid_Image (Image);

      for R in Image'Range (1) loop
         for C in Image'Range (2) loop
            if Image (R, C) then
               Result (R, C) := 0;
            else
               Best := Inf;
               for Fr in Image'Range (1) loop
                  for Fc in Image'Range (2) loop
                     if Image (Fr, Fc) then
                        Dr := Integer (R) - Integer (Fr);
                        Dc := Integer (C) - Integer (Fc);
                        Cand := Natural (Dr * Dr + Dc * Dc);
                        if Cand < Best then
                           Best := Cand;
                        end if;
                     end if;
                  end loop;
               end loop;
               Result (R, C) := Best;
            end if;
         end loop;
      end loop;

      return Result;
   end Squared_Distance_Transform;

   function Distance_Transform
     (Image : Binary_Image) return Distance_Map
   is
      Sq     : constant Squared_Distance_Map :=
        Squared_Distance_Transform (Image);
      Result : Distance_Map (Image'Range (1), Image'Range (2));
   begin
      for R in Result'Range (1) loop
         for C in Result'Range (2) loop
            Result (R, C) :=
              Real (Math.Sqrt (Long_Float (Sq (R, C))));
         end loop;
      end loop;
      return Result;
   end Distance_Transform;

   function Distance_At
     (Map : Distance_Map; Row, Col : Positive) return Real
   is
   begin
      if Row < Map'First (1) or else Row > Map'Last (1)
        or else Col < Map'First (2) or else Col > Map'Last (2)
      then
         raise Invalid_Argument;
      end if;
      return Map (Row, Col);
   end Distance_At;

   function Squared_Distance_At
     (Map : Squared_Distance_Map; Row, Col : Positive) return Natural
   is
   begin
      if Row < Map'First (1) or else Row > Map'Last (1)
        or else Col < Map'First (2) or else Col > Map'Last (2)
      then
         raise Invalid_Argument;
      end if;
      return Map (Row, Col);
   end Squared_Distance_At;

   ---------------------------------------------------------------------------
   -- Meijster-style separable exact squared EDT
   --
   -- Phase 1 (per column): G(r,c) = min |r − fr| over features in column c
   --   (Inf if the column has no feature).
   -- Phase 2 (per row): lower envelope of parabolas
   --   f_i(x) = (x − i)² + G(r,i)²; evaluate at each column x.
   ---------------------------------------------------------------------------

   function Meijster_Squared_Distance_Transform
     (Image : Binary_Image) return Squared_Distance_Map
   is
      --  Nested helpers / types only; sizing locals come after validation.
      type Dist_Grid is
        array (Row_Index range <>, Col_Index range <>) of Natural;

      type Int_Vec is array (Positive range <>) of Integer;
      type Nat_Vec is array (Positive range <>) of Natural;

      --  Floor(sep) intersection of parabolas at integer sites I < U.
      function Sep (I, U : Integer; Gi, Gu : Natural) return Integer is
         Num : constant Integer :=
           (U * U - I * I)
           + Integer (Gu) * Integer (Gu)
           - Integer (Gi) * Integer (Gi);
         Den : constant Integer := 2 * (U - I);
      begin
         if Num >= 0 then
            return Num / Den;
         else
            return (Num - Den + 1) / Den;
         end if;
      end Sep;

   begin
      Require_Valid_Image (Image);

      declare
         W   : constant Positive := Image'Length (2);
         Inf : constant Natural :=
           Max_Height * Max_Height + Max_Width * Max_Width;
         G : Dist_Grid (Image'Range (1), Image'Range (2));
         Result : Squared_Distance_Map (Image'Range (1), Image'Range (2));
      begin

         --  Phase 1: vertical 1-D DT per column
         for C in Image'Range (2) loop
            if Image (Image'First (1), C) then
               G (Image'First (1), C) := 0;
            else
               G (Image'First (1), C) := Inf;
            end if;

            for R in Image'First (1) + 1 .. Image'Last (1) loop
               if Image (R, C) then
                  G (R, C) := 0;
               elsif G (R - 1, C) >= Inf then
                  G (R, C) := Inf;
               else
                  G (R, C) := G (R - 1, C) + 1;
               end if;
            end loop;

            for R in reverse Image'First (1) .. Image'Last (1) - 1 loop
               if G (R + 1, C) < Inf
                 and then G (R + 1, C) + 1 < G (R, C)
               then
                  G (R, C) := G (R + 1, C) + 1;
               end if;
            end loop;
         end loop;

         --  Phase 2: horizontal lower envelope of parabolas per row
         for R in Image'Range (1) loop
            declare
               First_C : constant Col_Index := Image'First (2);
               Last_C  : constant Col_Index := Image'Last (2);
               Sites   : Int_Vec (1 .. W);  -- column indices of envelope sites
               Starts  : Int_Vec (1 .. W);  -- first column of each segment
               Gt      : Nat_Vec (1 .. W);  -- G at those sites
               Q       : Natural := 0;
               U, S    : Integer;
            begin
               for C in First_C .. Last_C loop
                  if G (R, C) < Inf then
                     U := Integer (C);
                     if Q = 0 then
                        Q := 1;
                        Sites (1) := U;
                        Starts (1) := Integer (First_C);
                        Gt (1) := G (R, C);
                     else
                        --  Pop dominated sites
                        loop
                           exit when Q = 0;
                           S := Sep (Sites (Q), U, Gt (Q), G (R, C)) + 1;
                           exit when S > Starts (Q);
                           Q := Q - 1;
                        end loop;

                        if Q = 0 then
                           Q := 1;
                           Sites (1) := U;
                           Starts (1) := Integer (First_C);
                           Gt (1) := G (R, C);
                        else
                           S := Sep (Sites (Q), U, Gt (Q), G (R, C)) + 1;
                           if S <= Integer (Last_C) then
                              Q := Q + 1;
                              Sites (Q) := U;
                              Starts (Q) := S;
                              Gt (Q) := G (R, C);
                           end if;
                        end if;
                     end if;
                  end if;
               end loop;

               --  Has_Feature ⇒ ≥1 column with a feature ⇒ every row has ≥1
               --  finite G in that column after phase 1 ⇒ Q ≥ 1.
               pragma Assert (Q >= 1);

               declare
                  K  : Positive := 1;
                  Dx : Integer;
               begin
                  for C in First_C .. Last_C loop
                     while K < Q and then Integer (C) >= Starts (K + 1) loop
                        K := K + 1;
                     end loop;
                     Dx := Integer (C) - Sites (K);
                     Result (R, C) :=
                       Natural (Dx * Dx) + Gt (K) * Gt (K);
                  end loop;
               end;
            end;
         end loop;

         return Result;
      end;
   end Meijster_Squared_Distance_Transform;

   ---------------------------------------------------------------------------
   -- 3-4 chamfer two-pass approximation
   ---------------------------------------------------------------------------

   function Chamfer_Distance_Transform
     (Image : Binary_Image) return Distance_Map
   is
      type Cost_Map is
        array (Row_Index range <>, Col_Index range <>) of Natural;
      Inf  : constant Natural :=
        (Chamfer_Ortho + Chamfer_Diagonal)
        * (Max_Height + Max_Width + 1);
      Cost : Cost_Map (Image'Range (1), Image'Range (2));
      Result : Distance_Map (Image'Range (1), Image'Range (2));
      Cand : Natural;

      function Min_Nat (A, B : Natural) return Natural is
        (if A < B then A else B);

      function Neighbor (R, C : Integer) return Natural is
      begin
         if R < Integer (Image'First (1))
           or else R > Integer (Image'Last (1))
           or else C < Integer (Image'First (2))
           or else C > Integer (Image'Last (2))
         then
            return Inf;
         end if;
         return Cost (Row_Index (R), Col_Index (C));
      end Neighbor;

   begin
      Require_Valid_Image (Image);

      for R in Image'Range (1) loop
         for C in Image'Range (2) loop
            if Image (R, C) then
               Cost (R, C) := 0;
            else
               Cost (R, C) := Inf;
            end if;
         end loop;
      end loop;

      --  Forward pass
      for R in Image'Range (1) loop
         for C in Image'Range (2) loop
            Cand := Cost (R, C);
            Cand := Min_Nat
              (Cand, Neighbor (Integer (R) - 1, Integer (C))
               + Chamfer_Ortho);
            Cand := Min_Nat
              (Cand, Neighbor (Integer (R), Integer (C) - 1)
               + Chamfer_Ortho);
            Cand := Min_Nat
              (Cand, Neighbor (Integer (R) - 1, Integer (C) - 1)
               + Chamfer_Diagonal);
            Cand := Min_Nat
              (Cand, Neighbor (Integer (R) - 1, Integer (C) + 1)
               + Chamfer_Diagonal);
            Cost (R, C) := Cand;
         end loop;
      end loop;

      --  Backward pass
      for R in reverse Image'Range (1) loop
         for C in reverse Image'Range (2) loop
            Cand := Cost (R, C);
            Cand := Min_Nat
              (Cand, Neighbor (Integer (R) + 1, Integer (C))
               + Chamfer_Ortho);
            Cand := Min_Nat
              (Cand, Neighbor (Integer (R), Integer (C) + 1)
               + Chamfer_Ortho);
            Cand := Min_Nat
              (Cand, Neighbor (Integer (R) + 1, Integer (C) + 1)
               + Chamfer_Diagonal);
            Cand := Min_Nat
              (Cand, Neighbor (Integer (R) + 1, Integer (C) - 1)
               + Chamfer_Diagonal);
            Cost (R, C) := Cand;
         end loop;
      end loop;

      for R in Result'Range (1) loop
         for C in Result'Range (2) loop
            Result (R, C) :=
              Real (Cost (R, C)) / Real (Chamfer_Ortho);
         end loop;
      end loop;

      return Result;
   end Chamfer_Distance_Transform;

end Euclidean_Distance_Transform;
