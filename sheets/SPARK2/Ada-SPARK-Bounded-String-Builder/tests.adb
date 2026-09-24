pragma Ada_2022;
with Bounded_String_Builder;

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
begin
   Check_Small;
   Check_Large;
end Tests;
