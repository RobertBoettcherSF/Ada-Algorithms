pragma Ada_2022;
--  Own checks (V&V sweep, agent A3). Model-based: seeded random sequences
--  of Visit / Back / Forward are applied both to the history and to a
--  two-stack model (Behind: pages before the current one, oldest first;
--  Ahead: forward pages, nearest last; Cur: the shown page). Visit pushes
--  Cur onto Behind, clears Ahead and shows the new page; Back and Forward
--  move one page between the stacks. A call whose precondition fails
--  (no room after the current page, no page behind, no page ahead) must
--  raise Assertion_Error (tests run with -gnata) and change nothing.
--  After every step Length, Current_Index, Current_Page and every
--  Page_At are compared with the model.
with Ada.Text_IO;
with Ada.Assertions;
with Ada.Environment_Variables;
with Interfaces; use Interfaces;
with Design_Browser_History; use Design_Browser_History;

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
      Name : constant String := "Ada-SPARK-Design-Browser-History";
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
   function Next (N : Positive) return Natural is
   begin
      Seed := (Seed * 16_807) mod 2_147_483_647;
      return Natural (Seed mod Long_Long_Integer (N));
   end Next;

   type Stack is array (1 .. 16) of Natural;
   Behind, Ahead : Stack := [others => 0];
   NB, NA : Natural := 0;
   Cur    : Natural := 0;   --  0 = nothing shown yet
   H      : History;

   procedure Compare (Label : String) is
      Shown : constant Natural := (if Cur = 0 then 0 else NB + 1);
      Ok    : Boolean := Length (H) = Shown + NA and then Current_Index (H) = Shown;
   begin
      if Ok and then Cur /= 0 then
         Ok := Current_Page (H) = Cur;
         for I in 1 .. NB loop
            Ok := Ok and then Page_At (H, I) = Behind (I);
         end loop;
         if Ok then
            Ok := Page_At (H, NB + 1) = Cur;
         end if;
         for K in 1 .. NA loop
            Ok := Ok and then Page_At (H, NB + 1 + K) = Ahead (NA + 1 - K);
         end loop;
      end if;
      Report (Ok, Label);
   end Compare;

   Refused : Natural := 0;
begin
   for Run in 1 .. 2_000 loop
      H := Empty;
      NB := 0; NA := 0; Cur := 0;
      Compare ("empty");
      for Step in 1 .. 40 loop
         declare
            Op : constant Natural := Next (3);
            P  : constant Page := (if Next (4) = 0 then 1 + Next (3) else 1 + Next (100));
            Allowed : Boolean;
            Raised  : Boolean := False;
         begin
            case Op is
               when 0 =>
                  Allowed := (if Cur = 0 then True else NB + 1 < Capacity);
                  begin
                     Visit (H, P);
                  exception
                     when Ada.Assertions.Assertion_Error => Raised := True;
                  end;
                  if Allowed then
                     if Cur /= 0 then
                        NB := NB + 1;
                        Behind (NB) := Cur;
                     end if;
                     NA := 0;
                     Cur := P;
                  end if;
               when 1 =>
                  Allowed := Cur /= 0 and then NB > 0;
                  begin
                     Back (H);
                  exception
                     when Ada.Assertions.Assertion_Error => Raised := True;
                  end;
                  if Allowed then
                     NA := NA + 1;
                     Ahead (NA) := Cur;
                     Cur := Behind (NB);
                     NB := NB - 1;
                  end if;
               when others =>
                  Allowed := NA > 0;
                  begin
                     Forward (H);
                  exception
                     when Ada.Assertions.Assertion_Error => Raised := True;
                  end;
                  if Allowed then
                     NB := NB + 1;
                     Behind (NB) := Cur;
                     Cur := Ahead (NA);
                     NA := NA - 1;
                  end if;
            end case;
            if Raised then
               Refused := Refused + 1;
            end if;
            Report (Raised = not Allowed, "refused exactly when not allowed, op" & Op'Image);
            Compare ("after op" & Op'Image);
         end;
      end loop;
   end loop;
   Report (Refused > 0, "some calls were refused");
   Ada.Text_IO.Put_Line
     ("Own checks:" & Checked'Image & " checks," & Failures'Image
      & " failures (" & Refused'Image & " refused calls)");
   if Failures > 0 then
      raise Program_Error with "own checks failed";
   end if;
end Own_Checks;
