pragma Ada_2022;
--  Own tests for Pn_Counter (see tests/SOURCES.txt).
--  PN-Counter against an own model: Value = sum P - sum N; Merge = componentwise max, so it is
--  commutative, idempotent and keeps every increment of both replicas.
with Ada.Environment_Variables;
with Ada.Text_IO; use Ada.Text_IO;
with Pn_Counter; use Pn_Counter;

procedure Own_Checks is
   Failures : Natural := 0;
   Checked : Natural := 0;
   --  Random test inputs: fixed default seed, printed at start; AA_SEED=<n> overrides it.
   function AA_Seed (Default : Long_Long_Integer) return Long_Long_Integer is
      V : constant String := Ada.Environment_Variables.Value ("AA_SEED", "");
      S : Long_Long_Integer := Default;
   begin
      if V /= "" then
         S := Long_Long_Integer (1 + abs (Long_Long_Integer'Value (V)) mod 2_147_483_646);
      end if;
      Ada.Text_IO.Put_Line ("AA_SEED =" & Long_Long_Integer'Image (S) & (if V = "" then " (default)" else " (from AA_SEED)"));
      return S;
   end AA_Seed;
   Seed : Long_Long_Integer := AA_Seed (20261008);
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
   function Model_Value (C : Counter) return Integer is
      S : Integer := 0;
   begin
      for A in Actor_Id loop S := S + P_At (C, A) - N_At (C, A); end loop;
      return S;
   end Model_Value;
   procedure Random_Ops (C : in out Counter) is
   begin
      for K in 1 .. Next (0, 30) loop
         declare
            Who : constant Actor_Id := Next (1, Max_Actors);
         begin
            if Next (0, 1) = 0 then
               if P_At (C, Who) < Max_Ticks then Increment (C, Who); end if;
            elsif N_At (C, Who) < Max_Ticks then
               Decrement (C, Who);
            end if;
         end;
      end loop;
   end Random_Ops;
begin
   for Trial in 1 .. 20_000 loop
      declare
         A, B, AB, BA, AA : Counter := Empty;
         P_Before : array (Actor_Id) of Tick;
      begin
         Random_Ops (A); Random_Ops (B);
         for W in Actor_Id loop P_Before (W) := P_At (A, W); end loop;
         declare
            Before : constant Tick := P_At (A, 1);
         begin
            if Before < Max_Ticks then
               Increment (A, 1);
               Report (P_At (A, 1) = Before + 1 and then Value (A) = Model_Value (A), "increment");
            end if;
         end;
         AB := A; Merge (AB, B);
         BA := B; Merge (BA, A);
         AA := A; Merge (AA, A);
         Report (Value (A) = Model_Value (A) and then Value (B) = Model_Value (B), "value");
         Report ((for all W in Actor_Id => P_At (AB, W) = Tick'Max (P_At (A, W), P_At (B, W))
                    and then N_At (AB, W) = Tick'Max (N_At (A, W), N_At (B, W))), "merge is max");
         Report ((for all W in Actor_Id => P_At (AB, W) = P_At (BA, W) and then N_At (AB, W) = N_At (BA, W)), "commutative");
         Report ((for all W in Actor_Id => P_At (AA, W) = P_At (A, W) and then N_At (AA, W) = N_At (A, W)), "idempotent");
         Report (Value (AB) = Model_Value (AB), "merged value");
         pragma Unreferenced (P_Before);
      end;
   end loop;
   if Failures = 0 then
      Put_Line ("PASS own checks:" & Natural'Image (Checked) & " cases");
   else
      Put_Line ("FAIL own checks:" & Natural'Image (Failures) & " of" & Natural'Image (Checked));
      raise Program_Error;
   end if;
end Own_Checks;
