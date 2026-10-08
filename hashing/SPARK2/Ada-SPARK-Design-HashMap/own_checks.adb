--  Own tests for Design_HashMap (see tests/SOURCES.txt).
--  Model-based: random Put / Contains / Get sequences against an own array model (Put overwrites).
with Ada.Text_IO; use Ada.Text_IO;
with Design_HashMap; use Design_HashMap;

procedure Own_Checks is
   Failures : Natural := 0;
   Checked : Natural := 0;
   Seed : Long_Long_Integer := 20261008;
   function Next (Lo, Hi : Integer) return Integer is
   begin
      Seed := (Seed * 16807) mod 2147483647;   --  Park-Miller minimal standard
      return Lo + Integer (Seed mod Long_Long_Integer (Hi - Lo + 1));
   end Next;
   procedure Report (Ok : Boolean; Label : String) is
   begin
      Checked := Checked + 1;
      if not Ok then
         Failures := Failures + 1;
         if Failures <= 10 then Put_Line ("  FAIL own check: " & Label); end if;
      end if;
   end Report;
   M : Map;
   Has : array (Key) of Boolean;
   Val : array (Key) of Value;
begin
   for Run in 1 .. 2_000 loop
      M := Empty;
      Has := [others => False];
      Val := [others => 0];
      for K in Key loop
         Report (not Contains (M, K), "empty map contains a key");
      end loop;
      for Op in 1 .. 30 loop
         declare
            K : constant Key := Next (1, Capacity);
            V : constant Value := Next (Value'First, Value'Last);
         begin
            if Next (0, 1) = 0 then
               Put (M, K, V);
               Has (K) := True;
               Val (K) := V;
            end if;
            for Q in Key loop
               Report (Contains (M, Q) = Has (Q), "contains");
               if Has (Q) and then Contains (M, Q) then
                  Report (Get (M, Q) = Val (Q), "get");
               end if;
            end loop;
         end;
      end loop;
   end loop;
   if Failures = 0 then
      Put_Line ("PASS own checks:" & Natural'Image (Checked) & " cases");
   else
      Put_Line ("FAIL own checks:" & Natural'Image (Failures) & " of" & Natural'Image (Checked));
      raise Program_Error;
   end if;
end Own_Checks;
