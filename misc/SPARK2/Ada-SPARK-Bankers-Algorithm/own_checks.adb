pragma Ada_2022;
--  Own checks (V&V sweep, agent A3). Independent definition of safety: the
--  state is safe when SOME order of the 4 processes (all 24 are tried)
--  lets each one in turn get its whole need (Maximum - Allocation, 0 when
--  Allocation exceeds Maximum, as Need's Post states) from the free
--  resources and then return its allocation. Request is checked against
--  "granted exactly when N <= Available (R), N <= Need (P, R) and the
--  state after the grant is safe by the same definition; a grant moves N
--  from Available (R) to Allocation (P, R), a refusal changes nothing".
--  Seeded random states (values 0 .. 3 and 0 .. 20), plus every state of
--  one resource with Available 0 .. 2 and allocation / maximum 0 .. 2.
with Ada.Text_IO;
with Ada.Environment_Variables;
with Interfaces; use Interfaces;
with Bankers_Algorithm; use Bankers_Algorithm;

procedure Own_Checks is
   Failures : Natural := 0;
   Checked  : Natural := 0;

   procedure Report (Ok : Boolean; Label : String) is
   begin
      Checked := Checked + 1;
      if not Ok then
         Failures := Failures + 1;
         if Failures <= 10 then
            Ada.Text_IO.Put_Line ("  FAIL own check: " & Label);
         end if;
      end if;
   end Report;

   function Name_Hash return Long_Long_Integer is
      Name : constant String := "Ada-SPARK-Bankers-Algorithm";
      H    : Unsigned_32 := 2_166_136_261;
   begin
      for C of Name loop
         H := (H xor Unsigned_32 (Character'Pos (C))) * 16_777_619;
      end loop;
      return Long_Long_Integer (H) mod 2_147_483_646 + 1;
   end Name_Hash;

   function AA_Seed (Default : Long_Long_Integer) return Long_Long_Integer is
      V : constant String := Ada.Environment_Variables.Value ("AA_SEED", "");
      S : constant Long_Long_Integer :=
        (if V = "" then Default
         else 1 + abs (Long_Long_Integer'Value (V)) mod 2_147_483_646);
   begin
      Ada.Text_IO.Put_Line
        ("AA_SEED =" & S'Image
         & (if V = "" then " (default: FNV-1a of the folder name)"
            else " (from AA_SEED)"));
      return S;
   end AA_Seed;

   Seed : Long_Long_Integer := AA_Seed (Name_Hash);
   function Next return Natural is
   begin
      Seed := (Seed * 16_807) mod 2_147_483_647;
      return Natural (Seed);
   end Next;

   function Ref_Need (S : State; P : Process_Id; R : Resource_Id) return Integer is
     (Integer'Max (0, S.Maximum (P, R) - S.Allocation (P, R)));

   type Order is array (1 .. Max_Processes) of Process_Id;

   function Works (S : State; O : Order) return Boolean is
      Free : array (Resource_Id) of Integer;
   begin
      for R in Resource_Id loop
         Free (R) := S.Available (R);
      end loop;
      for K in O'Range loop
         for R in Resource_Id loop
            if Ref_Need (S, O (K), R) > Free (R) then
               return False;
            end if;
         end loop;
         for R in Resource_Id loop
            Free (R) := Free (R) + S.Allocation (O (K), R);
         end loop;
      end loop;
      return True;
   end Works;

   function Ref_Safe (S : State) return Boolean is
      O : Order;
   begin
      for A in Process_Id loop
         for B in Process_Id loop
            for C in Process_Id loop
               for D in Process_Id loop
                  if A /= B and then A /= C and then A /= D and then B /= C
                    and then B /= D and then C /= D
                  then
                     O := [A, B, C, D];
                     if Works (S, O) then
                        return True;
                     end if;
                  end if;
               end loop;
            end loop;
         end loop;
      end loop;
      return False;
   end Ref_Safe;

   procedure Check_State (S : State; Label : String) is
      T : State;
      G : Boolean;
      Want : Boolean;
      P : constant Process_Id := Next mod Max_Processes + 1;
      R : constant Resource_Id := Next mod Max_Resources + 1;
      N : constant Amount := Next mod 4;
   begin
      Report (Is_Safe (S) = Ref_Safe (S), Label & ": Is_Safe");
      for PP in Process_Id loop
         for RR in Resource_Id loop
            Report (Need (S, PP, RR) = Ref_Need (S, PP, RR), Label & ": Need");
         end loop;
      end loop;
      if S.Maximum (P, R) >= S.Allocation (P, R) then
         T := S;
         Want := N <= S.Available (R) and then N <= Ref_Need (S, P, R);
         if Want then
            declare
               After : State := S;
            begin
               After.Available (R) := After.Available (R) - N;
               After.Allocation (P, R) := After.Allocation (P, R) + N;
               Want := Ref_Safe (After);
               Request (T, P, R, N, G);
               Report (G = Want, Label & ": Request granted");
               Report ((if Want then T = After else T = S),
                       Label & ": Request effect");
            end;
         else
            Request (T, P, R, N, G);
            Report (not G and then T = S, Label & ": Request refused");
         end if;
      end if;
   end Check_State;

   S : State;
begin
   --  Every one-resource state on 3 processes (the fourth idle; resources
   --  2 and 3 empty): Available 0 .. 2, Allocation 0 .. 2 and Maximum =
   --  Allocation + 0 .. 2 for each process (3 ** 7 states).
   for Code in 0 .. 3 ** 7 - 1 loop
      declare
         C : Natural := Code;
      begin
         S := (Available => [others => 0],
               Allocation => [others => [others => 0]],
               Maximum => [others => [others => 0]]);
         S.Available (1) := C mod 3; C := C / 3;
         for P in 1 .. 3 loop
            S.Allocation (P, 1) := C mod 3; C := C / 3;
            S.Maximum (P, 1) := S.Allocation (P, 1) + C mod 3; C := C / 3;
         end loop;
         Check_State (S, "one resource code" & Code'Image);
      end;
   end loop;
   for Trial in 1 .. 20_000 loop
      declare
         Hi : constant Natural := (if Trial mod 3 = 0 then 20 else 3);
      begin
         for R in Resource_Id loop
            S.Available (R) := Next mod (Hi + 1);
            for P in Process_Id loop
               S.Allocation (P, R) := Next mod (Hi + 1);
               --  Mostly valid states (Allocation <= Maximum); some not.
               if Trial mod 10 = 0 then
                  S.Maximum (P, R) := Next mod (Hi + 1);
               else
                  S.Maximum (P, R) :=
                    Natural'Min (20, S.Allocation (P, R) + Next mod (Hi + 1));
               end if;
            end loop;
         end loop;
         Check_State (S, "random trial" & Trial'Image);
      end;
   end loop;
   Ada.Text_IO.Put_Line
     ("Own checks:" & Checked'Image & " checks," & Failures'Image
      & " failures");
   if Failures > 0 then
      raise Program_Error with "own checks failed";
   end if;
end Own_Checks;
