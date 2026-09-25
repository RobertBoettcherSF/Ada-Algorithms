--  CLI explorer: list algorithms; run tests by category or all.
--  Spawns bin/test_* binaries built by the Makefile and aggregates exit codes.

pragma Ada_2022;

with Ada.Command_Line; use Ada.Command_Line;
with Ada.Text_IO;      use Ada.Text_IO;
with GNAT.OS_Lib;
with Categories;       use Categories;

procedure Harness is

   --  Directory containing this executable (…/bin), or "bin" if unknown.
   function Exec_Dir return String is
      Exe   : constant String := Command_Name;
      Slash : Natural := 0;
   begin
      for I in reverse Exe'Range loop
         if Exe (I) = '/' then
            Slash := I;
            exit;
         end if;
      end loop;
      if Slash = 0 then
         return "bin";
      else
         return Exe (Exe'First .. Slash - 1);
      end if;
   end Exec_Dir;

   function Test_Path (Basename : String) return String is
   begin
      return Exec_Dir & "/" & Basename;
   end Test_Path;

   procedure Usage is
   begin
      Put_Line ("Usage: harness --list");
      Put_Line ("       harness --category <name>");
      Put_Line ("       harness --all");
      Put_Line ("Categories: sorting, searching, numerical");
   end Usage;

   procedure Do_List is
   begin
      Put_Line ("Algorithms:");
      for I in Algo_Index range 1 .. Algo_Index (Registry_Length) loop
         declare
            E : constant Algo_Entry := Get (I);
         begin
            Put_Line
              ("  " & Name_Of (E)
               & "  [" & Category_Label (E.Category) & "]");
         end;
      end loop;
   end Do_List;

   function Run_One (E : Algo_Entry) return Boolean is
      Path : constant String := Test_Path (Bin_Of (E));
      Args : constant GNAT.OS_Lib.Argument_List (1 .. 0) := [others => <>];
      Code : Integer;
      OK   : Boolean;
   begin
      Put_Line
        ("---- " & Name_Of (E)
         & " (" & Category_Label (E.Category) & ") ----");
      if not GNAT.OS_Lib.Is_Executable_File (Path) then
         Put_Line ("  FAIL: missing executable: " & Path);
         return False;
      end if;
      Code := GNAT.OS_Lib.Spawn (Path, Args);
      OK := Code = 0;
      if OK then
         Put_Line ("  => PASS (exit 0)");
      else
         Put_Line ("  => FAIL (exit" & Integer'Image (Code) & ")");
      end if;
      return OK;
   end Run_One;

   Passes : Natural := 0;
   Fails  : Natural := 0;

   procedure Tally (OK : Boolean) is
   begin
      if OK then
         Passes := Passes + 1;
      else
         Fails := Fails + 1;
      end if;
   end Tally;

   procedure Run_Category (C : Category_Id) is
   begin
      for I in Algo_Index range 1 .. Algo_Index (Registry_Length) loop
         declare
            E : constant Algo_Entry := Get (I);
         begin
            if E.Category = C then
               Tally (Run_One (E));
            end if;
         end;
      end loop;
   end Run_Category;

   procedure Run_All is
   begin
      for I in Algo_Index range 1 .. Algo_Index (Registry_Length) loop
         Tally (Run_One (Get (I)));
      end loop;
   end Run_All;

   procedure Summary is
   begin
      New_Line;
      Put_Line
        ("Summary: " & Natural'Image (Passes) & " PASS,"
         & Natural'Image (Fails) & " FAIL");
      if Fails /= 0 then
         Set_Exit_Status (Failure);
      else
         Set_Exit_Status (Success);
      end if;
   end Summary;

begin
   if Argument_Count = 0 then
      Usage;
      Set_Exit_Status (Failure);
      return;
   end if;

   declare
      Arg1 : constant String := Argument (1);
   begin
      if Arg1 = "--list" or else Arg1 = "-l" then
         Do_List;
         Set_Exit_Status (Success);

      elsif Arg1 = "--all" or else Arg1 = "-a" then
         Run_All;
         Summary;

      elsif Arg1 = "--category" or else Arg1 = "-c" then
         if Argument_Count < 2 then
            Put_Line ("error: --category needs a name");
            Usage;
            Set_Exit_Status (Failure);
         else
            declare
               C : Category_Id;
            begin
               C := Parse_Category (Argument (2));
               Run_Category (C);
               Summary;
            exception
               when Constraint_Error =>
                  Put_Line ("error: unknown category: " & Argument (2));
                  Usage;
                  Set_Exit_Status (Failure);
            end;
         end if;

      elsif Arg1 = "--help" or else Arg1 = "-h" then
         Usage;
         Set_Exit_Status (Success);

      else
         Put_Line ("error: unknown option: " & Arg1);
         Usage;
         Set_Exit_Status (Failure);
      end if;
   end;
end Harness;
