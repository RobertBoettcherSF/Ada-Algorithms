pragma Ada_2022;

package body Bounded_String_Builder
  with SPARK_Mode => On
is

   procedure Clear (B : out Builder) is
   begin
      B := (Data => [others => Character'First], Len => 0);
   end Clear;

   procedure Append
     (B      : in out Builder;
      Item   : Character;
      Status : out Boolean)
   is
   begin
      if B.Len = Capacity then
         Status := False;
         return;
      end if;
      B.Len := B.Len + 1;
      B.Data (B.Len) := Item;
      Status := True;
   end Append;

   procedure Append
     (B      : in out Builder;
      Item   : String;
      Status : out Boolean)
   is
      Old_Len : constant Length_Type := B.Len;
   begin
      if Item'Length > Capacity - Old_Len then
         Status := False;
         return;
      end if;

      for I in Item'Range loop
         pragma Loop_Invariant (B.Len = Old_Len + (I - Item'First));
         pragma Loop_Invariant (B.Len <= Capacity - 1);
         pragma Loop_Invariant
           (for all K in Index_Type range 1 .. Old_Len =>
              B.Data (K) = B.Data'Loop_Entry (K));
         B.Len := B.Len + 1;
         B.Data (B.Len) := Item (I);
      end loop;

      Status := True;
   end Append;

   procedure Append_Integer
     (B      : in out Builder;
      Value  : Integer;
      Status : out Boolean)
   is
      --  Build the full decimal text first, then one Append — Status is
      --  atomic (builder unchanged on failure). No Integer'Image.
      Rev   : String (1 .. 10) := [others => '0'];
      Count : Natural := 0;
      T     : Natural;
      Neg   : constant Boolean := Value < 0;
   begin
      if Value = Integer'First then
         Append (B, "-2147483648", Status);
         return;
      end if;

      if Value = 0 then
         Append (B, '0', Status);
         return;
      end if;

      if Neg then
         T := Natural (-Value);
      else
         T := Natural (Value);
      end if;

      for K in 1 .. 10 loop
         pragma Loop_Invariant (Count = K - 1);
         Count := K;
         Rev (K) :=
           Character'Val (Character'Pos ('0') + Integer (T rem 10));
         T := T / 10;
         exit when T = 0;
      end loop;

      declare
         Need   : constant Positive := Count + (if Neg then 1 else 0);
         Result : String (1 .. Need) := [others => '0'];
         Offset : constant Natural := (if Neg then 1 else 0);
      begin
         if Neg then
            Result (1) := '-';
         end if;
         for I in 1 .. Count loop
            pragma Loop_Invariant (Offset + I <= Need);
            Result (Offset + I) := Rev (Count - I + 1);
         end loop;
         Append (B, Result, Status);
      end;
   end Append_Integer;

   procedure To_String
     (B      : Builder;
      Target : out String;
      Last   : out Natural)
   is
   begin
      Target := [others => Character'First];

      if B.Len = 0 then
         Last := 0;
         return;
      end if;

      for I in 1 .. B.Len loop
         pragma Loop_Invariant
           (for all K in 1 .. I - 1 => Target (K) = B.Data (K));
         Target (I) := B.Data (I);
      end loop;
      Last := B.Len;
   end To_String;

   procedure Slice
     (B      : Builder;
      Low    : Positive;
      High   : Natural;
      Target : out String;
      Last   : out Natural)
   is
   begin
      Target := [others => Character'First];

      if High < Low then
         Last := 0;
         return;
      end if;

      declare
         Count : constant Positive := High - Low + 1;
      begin
         for I in 1 .. Count loop
            pragma Loop_Invariant
              (for all K in 1 .. I - 1 =>
                 Target (K) = B.Data (Low + K - 1));
            Target (I) := B.Data (Low + I - 1);
         end loop;
         Last := Count;
      end;
   end Slice;

   function Equals (Left : Builder; Right : String) return Boolean is
   begin
      if Left.Len /= Right'Length then
         return False;
      end if;

      for I in 1 .. Left.Len loop
         pragma Loop_Invariant
           (for all K in 1 .. I - 1 => Left.Data (K) = Right (K));
         if Left.Data (I) /= Right (I) then
            return False;
         end if;
      end loop;

      return True;
   end Equals;

end Bounded_String_Builder;
