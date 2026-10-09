pragma Ada_2022;
with Ada.Text_IO;
with Bounded_String_Builder;
with Own_Checks;

--  Two instantiations teach the generics idea: same algorithm, different
--  Capacity formal objects (Wikibooks Ada Programming/Generics / RM 12).
procedure Tests is
   package Small is new Bounded_String_Builder (Capacity => 16);
   package Large is new Bounded_String_Builder (Capacity => 64);

   procedure Check_Small is
      B      : Small.Builder;
      Ok     : Boolean;
      Buf    : String (1 .. 16);
      Last   : Natural;
      SliceB : String (1 .. 8);
      SLast  : Natural;
   begin
      Small.Clear (B);
      pragma Assert (Small.Length (B) = 0);
      pragma Assert (Small.Max_Capacity = 16);

      Small.Append (B, "Hello", Ok);
      pragma Assert (Ok);
      pragma Assert (Small.Length (B) = 5);
      pragma Assert (Small.Equals (B, "Hello"));

      Small.Append (B, ',', Ok);
      pragma Assert (Ok);
      Small.Append (B, ' ', Ok);
      pragma Assert (Ok);
      Small.Append_Integer (B, 42, Ok);
      pragma Assert (Ok);
      pragma Assert (Small.Equals (B, "Hello, 42"));

      Small.To_String (B, Buf, Last);
      pragma Assert (Last = 9);
      pragma Assert (Buf (1 .. Last) = "Hello, 42");

      Small.Slice (B, 1, 5, SliceB, SLast);
      pragma Assert (SLast = 5);
      pragma Assert (SliceB (1 .. SLast) = "Hello");

      --  Capacity exhaustion fails cleanly (Status = False, length unchanged).
      declare
         Before : constant Small.Length_Type := Small.Length (B);
      begin
         Small.Append (B, "***************", Ok);  -- 15 chars; room left = 7
         pragma Assert (not Ok);
         pragma Assert (Small.Length (B) = Before);
      end;

      Small.Clear (B);
      pragma Assert (Small.Length (B) = 0);
      Small.To_String (B, Buf, Last);
      pragma Assert (Last = 0);
   end Check_Small;

   procedure Check_Large is
      B    : Large.Builder;
      Ok   : Boolean;
      Buf  : String (1 .. 64);
      Last : Natural;
   begin
      Large.Clear (B);
      pragma Assert (Large.Max_Capacity = 64);

      Large.Append (B, "Ada", Ok);
      pragma Assert (Ok);
      Large.Append (B, '/', Ok);
      pragma Assert (Ok);
      Large.Append (B, "SPARK", Ok);
      pragma Assert (Ok);
      Large.Append (B, ' ', Ok);
      pragma Assert (Ok);
      Large.Append_Integer (B, -7, Ok);
      pragma Assert (Ok);
      pragma Assert (Large.Equals (B, "Ada/SPARK -7"));

      Large.To_String (B, Buf, Last);
      pragma Assert (Buf (1 .. Last) = "Ada/SPARK -7");

      Large.Clear (B);
      for I in 1 .. 60 loop
         Large.Append (B, 'x', Ok);
         pragma Assert (Ok);
      end loop;
      pragma Assert (Large.Length (B) = 60);
      Large.Append (B, "abcdefghij", Ok);  -- 10 chars, only 4 free
      pragma Assert (not Ok);
      pragma Assert (Large.Length (B) = 60);
   end Check_Large;
   --  Hand-worked edge cases (V&V sweep, agent A3).
   procedure Check_Edges is
      B    : Small.Builder;
      Ok   : Boolean;
      Buf  : String (1 .. 16);
      Last : Natural;
   begin
      --  A string that fills the builder exactly is accepted.
      Small.Clear (B);
      Small.Append (B, "abcdef", Ok);
      Small.Append (B, "ghijklmnop", Ok);  -- 6 + 10 = 16
      pragma Assert (Ok and then Small.Length (B) = 16);
      pragma Assert (Small.Equals (B, "abcdefghijklmnop"));
      Small.Append (B, 'q', Ok);
      pragma Assert (not Ok and then Small.Length (B) = 16);
      Small.Append (B, "", Ok);  -- nothing to add still fits
      pragma Assert (Ok and then Small.Length (B) = 16);

      --  Single digits, ten-digit values and both ends of Integer.
      Small.Clear (B);
      Small.Append_Integer (B, 1, Ok);
      Small.Append_Integer (B, 0, Ok);
      Small.Append_Integer (B, -1, Ok);
      pragma Assert (Ok and then Small.Equals (B, "10-1"));
      Small.Clear (B);
      Small.Append_Integer (B, 1_000_000_000, Ok);
      pragma Assert (Ok and then Small.Equals (B, "1000000000"));
      Small.Clear (B);
      Small.Append_Integer (B, Integer'Last, Ok);
      pragma Assert (Ok and then Small.Equals (B, "2147483647"));
      Small.Clear (B);
      Small.Append_Integer (B, Integer'First, Ok);
      pragma Assert (Ok and then Small.Equals (B, "-2147483648"));
      Small.Append_Integer (B, -99_999, Ok);  -- 11 + 6 = 17 > 16
      pragma Assert (not Ok and then Small.Length (B) = 11);
      Small.Append_Integer (B, 99_999, Ok);  -- 11 + 5 = 16
      pragma Assert (Ok and then Small.Equals (B, "-214748364899999"));

      --  An empty slice gives Last = 0.
      Small.Slice (B, 4, 3, Buf, Last);
      pragma Assert (Last = 0);
      Small.Slice (B, 12, 16, Buf, Last);
      pragma Assert (Last = 5 and then Buf (1 .. 5) = "99999");
   end Check_Edges;
begin
   Check_Small;
   Check_Large;
   Check_Edges;
   Own_Checks;
   Ada.Text_IO.Put_Line ("bounded string builder: PASS");
end Tests;
