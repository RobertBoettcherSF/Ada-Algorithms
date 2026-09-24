--  Geometric_Hashing body — 2-D similarity geometric hashing sketch.

pragma Ada_2022;

with Ada.Numerics.Long_Elementary_Functions;

package body Geometric_Hashing
  with SPARK_Mode => Off
is

   package Math renames Ada.Numerics.Long_Elementary_Functions;

   ---------------------------------------------------------------------------
   -- Validation
   ---------------------------------------------------------------------------

   procedure Require_Model_Or_Scene (N : Natural) is
   begin
      if N < 3 or else N > Max_Points then
         raise Invalid_Argument;
      end if;
   end Require_Model_Or_Scene;

   procedure Require_Positive_Bin (Bin_Size : Real) is
   begin
      if Bin_Size <= 0.0 then
         raise Invalid_Argument;
      end if;
   end Require_Positive_Bin;

   ---------------------------------------------------------------------------
   -- Numeric helpers
   ---------------------------------------------------------------------------

   function Near (A, B : Real; Tol : Real := Epsilon) return Boolean is
   begin
      return abs (A - B) <= Tol;
   end Near;

   function Near_Point (A, B : Point; Tol : Real := Epsilon) return Boolean is
   begin
      return Near (A.X, B.X, Tol) and then Near (A.Y, B.Y, Tol);
   end Near_Point;

   function Dist2 (A, B : Point) return Real is
      Dx : constant Real := B.X - A.X;
      Dy : constant Real := B.Y - A.Y;
   begin
      return Dx * Dx + Dy * Dy;
   end Dist2;

   function Dist (A, B : Point) return Real is
   begin
      return Real (Math.Sqrt (Long_Float (Dist2 (A, B))));
   end Dist;

   function Same_Key (A, B : Hash_Key) return Boolean is
   begin
      return A.U = B.U and then A.V = B.V;
   end Same_Key;

   ---------------------------------------------------------------------------
   -- Basis / quantization
   ---------------------------------------------------------------------------

   function Make_Basis (A, B : Point) return Basis is
      Dx  : constant Real := B.X - A.X;
      Dy  : constant Real := B.Y - A.Y;
      Len2 : constant Real := Dx * Dx + Dy * Dy;
      Len : Real;
      Inv : Real;
      Result : Basis;
   begin
      if Len2 < Epsilon * Epsilon then
         Result.Valid := False;
         return Result;
      end if;

      Len := Real (Math.Sqrt (Long_Float (Len2)));
      Inv := 1.0 / Len;
      Result.Origin :=
        (X => 0.5 * (A.X + B.X), Y => 0.5 * (A.Y + B.Y));
      Result.Ux := (X => Dx * Inv, Y => Dy * Inv);
      Result.Uy := (X => -Result.Ux.Y, Y => Result.Ux.X);
      Result.Scale := 0.5 * Len;
      Result.Valid := Result.Scale >= Epsilon;
      return Result;
   end Make_Basis;

   function To_Basis_Coords (P : Point; B : Basis) return Point is
      Vx, Vy : Real;
      Inv_S  : Real;
   begin
      if not B.Valid or else B.Scale < Epsilon then
         return (X => 0.0, Y => 0.0);
      end if;
      Vx := P.X - B.Origin.X;
      Vy := P.Y - B.Origin.Y;
      Inv_S := 1.0 / B.Scale;
      return
        (X => (Vx * B.Ux.X + Vy * B.Ux.Y) * Inv_S,
         Y => (Vx * B.Uy.X + Vy * B.Uy.Y) * Inv_S);
   end To_Basis_Coords;

   function Quantize
     (UV : Point; Bin_Size : Real := Default_Bin_Size) return Hash_Key
   is
   begin
      Require_Positive_Bin (Bin_Size);
      return
        (U => Integer (Real'Rounding (UV.X / Bin_Size)),
         V => Integer (Real'Rounding (UV.Y / Bin_Size)));
   end Quantize;

   function Quantize_Point
     (P        : Point;
      B        : Basis;
      Bin_Size : Real := Default_Bin_Size) return Hash_Key
   is
   begin
      return Quantize (To_Basis_Coords (P, B), Bin_Size);
   end Quantize_Point;

   ---------------------------------------------------------------------------
   -- Hash table
   ---------------------------------------------------------------------------

   function Empty_Table
     (Bin_Size : Real := Default_Bin_Size) return Hash_Table
   is
      T : Hash_Table;
   begin
      Require_Positive_Bin (Bin_Size);
      T.Count := 0;
      T.Bin_Size := Bin_Size;
      return T;
   end Empty_Table;

   function Entry_Length (Table : Hash_Table) return Entry_Count is
   begin
      return Table.Count;
   end Entry_Length;

   procedure Append_Entry
     (Table : in out Hash_Table; E : Table_Entry)
   is
   begin
      if Table.Count = Max_Entries then
         raise Invalid_Argument;
      end if;
      Table.Count := Table.Count + 1;
      Table.Entries (Table.Count) := E;
   end Append_Entry;

   function Build_Table
     (Model     : Point_Array;
      Model_Id  : Natural := 1;
      Bin_Size  : Real := Default_Bin_Size) return Hash_Table
   is
      Table : Hash_Table;
      B     : Basis;
      Key   : Hash_Key;
   begin
      Require_Model_Or_Scene (Model'Length);
      Require_Positive_Bin (Bin_Size);
      if Model_Id = 0 then
         raise Invalid_Argument;
      end if;

      Table := Empty_Table (Bin_Size);

      for I in Model'Range loop
         for J in Model'Range loop
            if I /= J then
               B := Make_Basis (Model (I), Model (J));
               if B.Valid then
                  for K in Model'Range loop
                     if K /= I and then K /= J then
                        Key := Quantize_Point (Model (K), B, Bin_Size);
                        Append_Entry
                          (Table,
                           (Key      => Key,
                            Model_Id => Model_Id,
                            Basis_I  => Point_Index (I),
                            Basis_J  => Point_Index (J)));
                     end if;
                  end loop;
               end if;
            end if;
         end loop;
      end loop;

      return Table;
   end Build_Table;

   function Lookup_Count
     (Table : Hash_Table; Key : Hash_Key) return Natural
   is
      N : Natural := 0;
   begin
      for E of Table.Entries (1 .. Table.Count) loop
         if Same_Key (E.Key, Key) then
            N := N + 1;
         end if;
      end loop;
      return N;
   end Lookup_Count;

   ---------------------------------------------------------------------------
   -- Recognition voting (educational bounded vote map)
   ---------------------------------------------------------------------------

   --  Cap on simultaneous hypotheses tracked for one scene basis.
   Max_Hypotheses : constant Positive := 256;

   type Hypothesis is record
      Model_Id : Natural := 0;
      Basis_I  : Point_Index := 1;
      Basis_J  : Point_Index := 1;
      Votes    : Natural := 0;
   end record;

   type Hypothesis_Array is array (1 .. Max_Hypotheses) of Hypothesis;

   procedure Add_Vote
     (Hyps  : in out Hypothesis_Array;
      Count : in out Natural;
      E     : Table_Entry)
   is
      Found : Boolean := False;
   begin
      for H in 1 .. Count loop
         if Hyps (H).Model_Id = E.Model_Id
           and then Hyps (H).Basis_I = E.Basis_I
           and then Hyps (H).Basis_J = E.Basis_J
         then
            Hyps (H).Votes := Hyps (H).Votes + 1;
            Found := True;
            exit;
         end if;
      end loop;

      if not Found and then Count < Max_Hypotheses then
         Count := Count + 1;
         Hyps (Count) :=
           (Model_Id => E.Model_Id,
            Basis_I  => E.Basis_I,
            Basis_J  => E.Basis_J,
            Votes    => 1);
      end if;
   end Add_Vote;

   function Recognize
     (Scene       : Point_Array;
      Table       : Hash_Table;
      Min_Votes   : Natural := 1) return Recognition_Result
   is
      Best     : Recognition_Result;
      B        : Basis;
      Key      : Hash_Key;
      Hyps     : Hypothesis_Array;
      Hyp_N    : Natural;
      Local_Best_Votes : Natural;
      Local_Best_Idx   : Natural;
   begin
      Require_Model_Or_Scene (Scene'Length);
      if Table.Count = 0 then
         raise Invalid_Argument;
      end if;

      Best.Found := False;
      Best.Vote_Count := 0;

      for Si in Scene'Range loop
         for Sj in Scene'Range loop
            if Si /= Sj then
               B := Make_Basis (Scene (Si), Scene (Sj));
               if B.Valid then
                  Hyp_N := 0;
                  Hyps := [others => <>];

                  for Sk in Scene'Range loop
                     if Sk /= Si and then Sk /= Sj then
                        Key :=
                          Quantize_Point (Scene (Sk), B, Table.Bin_Size);
                        for E of Table.Entries (1 .. Table.Count) loop
                           if Same_Key (E.Key, Key) then
                              Add_Vote (Hyps, Hyp_N, E);
                           end if;
                        end loop;
                     end if;
                  end loop;

                  Local_Best_Votes := 0;
                  Local_Best_Idx := 0;
                  for H in 1 .. Hyp_N loop
                     if Hyps (H).Votes > Local_Best_Votes then
                        Local_Best_Votes := Hyps (H).Votes;
                        Local_Best_Idx := H;
                     end if;
                  end loop;

                  if Local_Best_Idx > 0
                    and then Local_Best_Votes >= Min_Votes
                    and then Local_Best_Votes > Best.Vote_Count
                  then
                     Best.Found := True;
                     Best.Model_Id := Hyps (Local_Best_Idx).Model_Id;
                     Best.Vote_Count := Local_Best_Votes;
                     Best.Scene_Basis :=
                       (I => Point_Index (Si), J => Point_Index (Sj));
                     Best.Model_Basis :=
                       (I => Hyps (Local_Best_Idx).Basis_I,
                        J => Hyps (Local_Best_Idx).Basis_J);
                  end if;
               end if;
            end if;
         end loop;
      end loop;

      return Best;
   end Recognize;

end Geometric_Hashing;
