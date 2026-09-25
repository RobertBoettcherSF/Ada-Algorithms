--  Version: 0.001
--  Mutation testing for the Modular_Arithmetic sheet, in Ada (no scripts).
--  Copies the sources to mutate_work/, then for every mutant of the core
--  package bodies applies one small change, rebuilds the test program
--  WITHOUT -gnata (so only the tests, not the contracts, can notice), runs
--  it with a time limit and records whether it failed ("killed").
--  Mutation operators:
--    relational   <  <=  >  >=  =  /=  replaced by a neighbour
--    logical      and then <-> or else, drop "not"
--    arithmetic   + <-> -,  * -> +,  / -> *
--    condition    if/elsif/while/exit when C  ->  not (C)
--    literal      integer literal N -> N + 1 (and 1 -> 0)
--  (mod -> rem is not used: every "mod" in these bodies has nonnegative
--  operands, where mod and rem agree, so such mutants are equivalent.)
--  Comments, strings, pragmas, contracts, with/use clauses and ghost code
--  (lemma calls "L.", Lemma_/Prove_/Halve subprograms, "with Ghost"
--  objects) are not mutated: ghost code has no run-time effect in the
--  build under test.  Mutants that do not compile are "stillborn" and not
--  counted.  Mutants listed in tools/mutation_equivalent.txt (with the
--  reason why they cannot change behaviour) are reported separately and
--  excluded from the kill rate.
--
--  Usage (from the sheet directory):  bin/mutate [--gnatmake=CMD]
--                                                [--only=FILE]

pragma Ada_2022;

with Ada.Command_Line;
with Ada.Containers.Indefinite_Vectors;
with Ada.Directories;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded;
with Ada.Text_IO;
with GNAT.OS_Lib;
with Interfaces.C;

procedure Mutate is

   use Ada.Text_IO;
   use Ada.Strings.Unbounded;

   package Str_Vectors is new Ada.Containers.Indefinite_Vectors
     (Positive, String);

   Core_Files : constant array (Positive range <>) of Unbounded_String :=
     [To_Unbounded_String ("modular_arithmetic.adb"),
      To_Unbounded_String ("modular_arithmetic-crt.adb"),
      To_Unbounded_String ("modular_arithmetic-montgomery.adb"),
      To_Unbounded_String ("modular_arithmetic-check_digits.adb")];

   Repo     : constant String := Ada.Directories.Current_Directory;
   Work     : constant String := Repo & "/mutate_work";
   Gnatmake : Unbounded_String := To_Unbounded_String ("gnatmake");
   Only     : Unbounded_String;
   Time_Limit : constant Duration := 20.0;

   ---------------------------------------------------------------- files

   function Read_Lines (Path : String) return Str_Vectors.Vector is
      F : File_Type;
      V : Str_Vectors.Vector;
   begin
      Open (F, In_File, Path);
      while not End_Of_File (F) loop
         V.Append (Get_Line (F));
      end loop;
      Close (F);
      return V;
   end Read_Lines;

   procedure Write_Lines (Path : String; V : Str_Vectors.Vector) is
      F : File_Type;
   begin
      Create (F, Out_File, Path);
      for L of V loop
         Put_Line (F, L);
      end loop;
      Close (F);
   end Write_Lines;

   --  Write a body and drop its object files so that it is recompiled
   --  (GNAT time stamps have a one-second resolution).
   procedure Write_Source (Name : String; V : Str_Vectors.Vector) is
      Base : constant String := Ada.Directories.Base_Name (Name);
      procedure Drop (Ext : String) is
      begin
         if Ada.Directories.Exists (Work & "/obj/" & Base & Ext) then
            Ada.Directories.Delete_File (Work & "/obj/" & Base & Ext);
         end if;
      end Drop;
   begin
      Write_Lines (Work & "/" & Name, V);
      Drop (".o");
      Drop (".ali");
   end Write_Source;

   procedure Copy_Sources is
      use Ada.Directories;
      S : Search_Type;
      E : Directory_Entry_Type;
   begin
      if Exists (Work) then
         Delete_Tree (Work);
      end if;
      Create_Path (Work & "/obj");
      Start_Search (S, Repo, "*.ad?", [Ordinary_File => True, others => False]);
      while More_Entries (S) loop
         Get_Next_Entry (S, E);
         Copy_File (Full_Name (E), Work & "/" & Simple_Name (E));
      end loop;
      End_Search (S);
   end Copy_Sources;

   ------------------------------------------------------------ processes

   function waitpid (Pid : Interfaces.C.int; Status : access Interfaces.C.int;
                     Options : Interfaces.C.int) return Interfaces.C.int
     with Import, Convention => C, External_Name => "waitpid";
   function kill (Pid : Interfaces.C.int; Sig : Interfaces.C.int)
     return Interfaces.C.int
     with Import, Convention => C, External_Name => "kill";

   type Run_Result is (Passed, Failed, Timed_Out);

   --  Run Program with Args, output to Log; wait at most Limit seconds.
   function Run (Program : String; Args : GNAT.OS_Lib.Argument_List;
                 Log : String; Limit : Duration) return Run_Result
   is
      use type Interfaces.C.int;
      Pid    : GNAT.OS_Lib.Process_Id;
      Id     : Interfaces.C.int;
      Status : aliased Interfaces.C.int := 0;
      Waited : Duration := 0.0;
      R      : Interfaces.C.int;
   begin
      Pid := GNAT.OS_Lib.Non_Blocking_Spawn (Program, Args, Log);
      if GNAT.OS_Lib."=" (Pid, GNAT.OS_Lib.Invalid_Pid) then
         return Failed;
      end if;
      Id := Interfaces.C.int (GNAT.OS_Lib.Pid_To_Integer (Pid));
      loop
         R := waitpid (Id, Status'Access, 1);   --  WNOHANG
         if R = Id then
            --  exited normally with code 0 <=> status word 0
            return (if Status = 0 then Passed else Failed);
         elsif R < 0 then
            return Failed;
         end if;
         delay 0.02;
         Waited := Waited + 0.02;
         if Waited > Limit then
            R := kill (Id, 9);
            R := waitpid (Id, Status'Access, 0);
            return Timed_Out;
         end if;
      end loop;
   end Run;

   function Build return Boolean is
      Exe  : constant GNAT.OS_Lib.String_Access :=
        GNAT.OS_Lib.Locate_Exec_On_Path (To_String (Gnatmake));
      Args : GNAT.OS_Lib.Argument_List :=
        [new String'("-q"), new String'("-gnat2022"), new String'("-gnatws"),
         new String'("-D"), new String'(Work & "/obj"),
         new String'("-I" & Work), new String'("-o"),
         new String'(Work & "/tests"), new String'(Work & "/tests.adb")];
      Ok : Boolean;
   begin
      if GNAT.OS_Lib."=" (Exe, null) then
         raise Program_Error with "cannot find " & To_String (Gnatmake);
      end if;
      if Ada.Directories.Exists (Work & "/tests") then
         Ada.Directories.Delete_File (Work & "/tests");
      end if;
      Ok := Run (Exe.all, Args, Work & "/build.log", 300.0) = Passed;
      for A of Args loop
         GNAT.OS_Lib.Free (A);
      end loop;
      return Ok and then Ada.Directories.Exists (Work & "/tests");
   end Build;

   function Run_Tests return Run_Result is
      No_Args : constant GNAT.OS_Lib.Argument_List (1 .. 0) := [others => <>];
   begin
      return Run (Work & "/tests", No_Args, Work & "/tests.log", Time_Limit);
   end Run_Tests;

   ------------------------------------------------------------- mutants

   type Mutant is record
      File    : Unbounded_String;
      Line    : Positive;
      Col     : Positive;
      Before  : Unbounded_String;   --  original text replaced
      After   : Unbounded_String;   --  replacement
   end record;

   package Mutant_Vectors is new Ada.Containers.Indefinite_Vectors
     (Positive, Mutant);

   Mutants : Mutant_Vectors.Vector;

   --  The code part of a line: comments and string / character literals
   --  are blanked out so that they are never mutated.
   function Code_Of (Line : String) return String is
      R  : String := Line;
      I  : Natural := R'First;
      In_Str : Boolean := False;
   begin
      while I <= R'Last loop
         if In_Str then
            if R (I) = '"' then
               In_Str := False;
            else
               R (I) := ' ';
            end if;
         elsif R (I) = '"' then
            In_Str := True;
         elsif R (I) = ''' and then I + 2 <= R'Last and then R (I + 2) = '''
           and then (I = R'First or else R (I - 1) not in 'A' .. 'Z' | 'a' .. 'z' | '0' .. '9' | '_')
         then
            R (I + 1) := ' ';
            I := I + 2;
         elsif R (I) = '-' and then I < R'Last and then R (I + 1) = '-' then
            R (I .. R'Last) := [others => ' '];
            exit;
         end if;
         I := I + 1;
      end loop;
      return R;
   end Code_Of;

   function Trim (S : String) return String is
     (Ada.Strings.Fixed.Trim (S, Ada.Strings.Both));

   function Starts (S, P : String) return Boolean is
     (S'Length >= P'Length and then S (S'First .. S'First + P'Length - 1) = P);

   function Ends (S, P : String) return Boolean is
     (S'Length >= P'Length and then S (S'Last - P'Length + 1 .. S'Last) = P);

   function Is_Ident (C : Character) return Boolean is
     (C in 'A' .. 'Z' | 'a' .. 'z' | '0' .. '9' | '_');

   procedure Add (File : String; Line, Col : Positive; Before, After : String)
   is
   begin
      Mutants.Append
        (Mutant'(To_Unbounded_String (File), Line, Col,
                 To_Unbounded_String (Before), To_Unbounded_String (After)));
   end Add;

   --  Find occurrences of word/operator W in Code (whole-word for names).
   procedure Find_Mutants (File : String) is
      Lines : constant Str_Vectors.Vector := Read_Lines (Repo & "/" & File);
      Skip_Until : Unbounded_String;   --  "end Name;" ending a ghost unit
      Skipping   : Boolean := False;   --  inside a multi-line skipped part
   begin
      for N in Lines.First_Index .. Lines.Last_Index loop
         declare
            Code : constant String := Code_Of (Lines (N));
            T    : constant String := Trim (Code);

            procedure Op (W : String; Repl : String) is
               K : Natural := Code'First;
            begin
               loop
                  K := Ada.Strings.Fixed.Index (Code (K .. Code'Last), W);
                  exit when K = 0;
                  declare
                     Last : constant Natural := K + W'Length - 1;
                     Word : constant Boolean := Is_Ident (W (W'First));
                     Ok   : Boolean := True;
                  begin
                     if Word then
                        Ok := (K = Code'First or else not Is_Ident (Code (K - 1)))
                          and then (Last = Code'Last
                                    or else not Is_Ident (Code (Last + 1)));
                     else
                        --  do not split compound symbols such as <= >= /= =>
                        Ok := (K = Code'First
                               or else Code (K - 1) not in '<' | '>' | '/' | '=' | ':')
                          and then (Last = Code'Last
                                    or else Code (Last + 1) not in '=' | '>');
                        if W = "*" and then Last < Code'Last
                          and then Code (Last + 1) = '*'
                        then
                           Ok := False;
                        end if;
                        if W = "*" and then K > Code'First
                          and then Code (K - 1) = '*'
                        then
                           Ok := False;
                        end if;
                     end if;
                     if Ok then
                        Add (File, N, K, W, Repl);
                     end if;
                     K := Last + 1;
                     exit when K > Code'Last;
                  end;
               end loop;
            end Op;

            procedure Literals is
               K : Natural := Code'First;
            begin
               while K <= Code'Last loop
                  if Code (K) in '0' .. '9'
                    and then (K = Code'First or else not Is_Ident (Code (K - 1)))
                  then
                     declare
                        J : Natural := K;
                     begin
                        while J < Code'Last
                          and then Code (J + 1) in '0' .. '9' | '_'
                        loop
                           J := J + 1;
                        end loop;
                        if (J = Code'Last or else not Is_Ident (Code (J + 1)))
                          and then (J = Code'Last or else Code (J + 1) /= '#')
                          and then (K = Code'First or else Code (K - 1) /= '*')
                        then
                           declare
                              Txt : constant String := Code (K .. J);
                              V   : Long_Long_Integer;
                           begin
                              V := Long_Long_Integer'Value (Txt);
                              Add (File, N, K, Txt,
                                   Trim (Long_Long_Integer'Image (V + 1)));
                              if V = 1 then
                                 Add (File, N, K, Txt, "0");
                              end if;
                           exception
                              when Constraint_Error => null;
                           end;
                        end if;
                        K := J + 1;
                     end;
                  else
                     K := K + 1;
                  end if;
               end loop;
            end Literals;

            procedure Condition (Keyword : String; Stop : String) is
               K : constant Natural := Ada.Strings.Fixed.Index (Code, Keyword);
               E : Natural;
            begin
               if K = 0 or else not Starts (T, Keyword) then
                  return;
               end if;
               E := (if Stop = "" then 0
                     else Ada.Strings.Fixed.Index (Code, Stop, Ada.Strings.Backward));
               if Stop = "" then
                  E := Ada.Strings.Fixed.Index (Code, ";", Ada.Strings.Backward);
               end if;
               if E > K + Keyword'Length then
                  declare
                     C : constant String :=
                       Trim (Code (K + Keyword'Length .. E - 1));
                     Src : constant String := Lines (N);
                  begin
                     if C'Length > 0 then
                        Add (File, N, K + Keyword'Length,
                             Src (K + Keyword'Length .. E - 1),
                             " not (" & Trim (Src (K + Keyword'Length .. E - 1))
                             & ") ");
                     end if;
                  end;
               end if;
            end Condition;

         begin
            if Length (Skip_Until) > 0 then
               if Starts (T, To_String (Skip_Until)) then
                  Skip_Until := Null_Unbounded_String;
               end if;
            elsif Starts (T, "procedure Lemma_") or else Starts (T, "procedure Halve")
              or else Starts (T, "procedure Prove_")
            then
               declare
                  Name_Start : constant Positive := T'First + 10;
                  Name_End   : Natural := Name_Start;
               begin
                  while Name_End < T'Last and then Is_Ident (T (Name_End + 1)) loop
                     Name_End := Name_End + 1;
                  end loop;
                  --  Only skip bodies (declarations end with ";").
                  Skip_Until := To_Unbounded_String
                    ("end " & T (Name_Start .. Name_End) & ";");
               end;
            elsif Skipping then
               --  continuation of a pragma / ghost call / contract
               if Ada.Strings.Fixed.Index (Code, ";") > 0
                 or else T = "is" or else Ends (T, " is")
               then
                  Skipping := False;
               end if;
            elsif T'Length = 0 then
               null;
            elsif Starts (T, "pragma") or else Starts (T, "with ")
              or else Starts (T, "use ") or else Starts (T, "L.")
              or else Starts (T, "Halve") or else Starts (T, "Lemma_")
              or else Starts (T, "Prove_")
              or else Ada.Strings.Fixed.Index (Code, "with Ghost") > 0
              or else Starts (T, "Pre ") or else Starts (T, "Post ")
              or else Starts (T, "Global ") or else Starts (T, "package ")
            then
               --  not mutated; may continue on the next lines
               Skipping := Ada.Strings.Fixed.Index (Code, ";") = 0
                 and then not Ends (T, " is") and then T /= "is";
            else
               Op ("<=", ">");   Op (">=", "<");
               Op ("<", "<=");   Op (">", ">=");
               Op ("/=", "=");   Op ("=", "/=");
               Op ("and then", "or else");
               Op ("or else", "and then");
               Op ("not ", "");
               Op ("+", "-");    Op ("-", "+");
               Op ("*", "+");    Op ("/", "*");
               Literals;
               Condition ("if ", " then");
               Condition ("elsif ", " then");
               Condition ("while ", " loop");
               Condition ("exit when ", "");
            end if;
         end;
      end loop;
   end Find_Mutants;

   -------------------------------------------------------- equivalents

   --  tools/mutation_equivalent.txt: one mutant per line,
   --    file | source line (trimmed) | before -> after | reason
   --  Lines starting with '#' are comments.
   Equivalents : Str_Vectors.Vector;

   function Key (File, Src, Before, After : String) return String is
     (File & " | " & Trim (Src) & " | " & Trim (Before) & " -> " & Trim (After));

   procedure Load_Equivalents is
      Path : constant String := Repo & "/tools/mutation_equivalent.txt";
   begin
      if not Ada.Directories.Exists (Path) then
         return;
      end if;
      for L of Read_Lines (Path) loop
         if L'Length > 0 and then L (L'First) /= '#' then
            declare
               Bar : constant Natural :=
                 Ada.Strings.Fixed.Index (L, " | ", Ada.Strings.Backward);
            begin
               if Bar > 0 then
                  Equivalents.Append (Trim (L (L'First .. Bar - 1)));
               end if;
            end;
         end if;
      end loop;
   end Load_Equivalents;

   ------------------------------------------------------------- driver

   Killed, Survived, Stillborn, Timeouts, Equivalent : Natural := 0;
   Survivors : Str_Vectors.Vector;

   function Describe (M : Mutant) return String is
     (To_String (M.File) & ":" & Trim (M.Line'Image) & ":" & Trim (M.Col'Image)
      & ": '" & Trim (To_String (M.Before)) & "' -> '"
      & Trim (To_String (M.After)) & "'");

begin
   for I in 1 .. Ada.Command_Line.Argument_Count loop
      declare
         A : constant String := Ada.Command_Line.Argument (I);
      begin
         if Starts (A, "--gnatmake=") then
            Gnatmake := To_Unbounded_String (A (A'First + 11 .. A'Last));
         elsif Starts (A, "--only=") then
            Only := To_Unbounded_String (A (A'First + 7 .. A'Last));
         else
            Put_Line ("usage: mutate [--gnatmake=CMD] [--only=FILE]");
            Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
            return;
         end if;
      end;
   end loop;

   Load_Equivalents;
   Copy_Sources;
   if not Build or else Run_Tests /= Passed then
      Put_Line ("error: the unmutated sources do not build or pass the tests");
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
      return;
   end if;

   for F of Core_Files loop
      if Length (Only) = 0 or else Only = F then
         Find_Mutants (To_String (F));
      end if;
   end loop;
   Put_Line ("mutants:" & Mutants.Length'Image);

   for M of Mutants loop
      declare
         Name  : constant String := To_String (M.File);
         Orig  : constant Str_Vectors.Vector := Read_Lines (Repo & "/" & Name);
         Mut   : Str_Vectors.Vector := Orig;
         L     : constant String := Orig (M.Line);
         B     : constant String := To_String (M.Before);
         New_L : constant String :=
           L (L'First .. M.Col - 1) & To_String (M.After)
           & L (M.Col + B'Length .. L'Last);
      begin
         if Equivalents.Contains
              (Key (Name, L, To_String (M.Before), To_String (M.After)))
         then
            Equivalent := Equivalent + 1;
            goto Next_Mutant;
         end if;
         Mut.Replace_Element (M.Line, New_L);
         Write_Source (Name, Mut);
         if not Build then
            Stillborn := Stillborn + 1;
         else
            case Run_Tests is
               when Passed =>
                  Survived := Survived + 1;
                  Survivors.Append
                    (Describe (M) & "   [" & Key (Name, L, To_String (M.Before),
                                                  To_String (M.After)) & "]");
                  Put_Line ("SURVIVED " & Describe (M));
               when Failed =>
                  Killed := Killed + 1;
               when Timed_Out =>
                  Killed := Killed + 1;
                  Timeouts := Timeouts + 1;
            end case;
         end if;
         Write_Source (Name, Orig);
      end;
      <<Next_Mutant>>
   end loop;

   New_Line;
   Put_Line ("Mutation summary");
   Put_Line ("  compiled mutants :" & Natural'Image (Killed + Survived));
   Put_Line ("  killed           :" & Natural'Image (Killed)
             & " (" & Trim (Timeouts'Image) & " by time-out)");
   Put_Line ("  survived         :" & Natural'Image (Survived));
   Put_Line ("  stillborn        :" & Natural'Image (Stillborn)
             & " (did not compile, not counted)");
   Put_Line ("  equivalent       :" & Natural'Image (Equivalent)
             & " (tools/mutation_equivalent.txt, not counted)");
   if Killed + Survived > 0 then
      Put_Line ("  kill rate        :"
                & Natural'Image ((Killed * 1000 / (Killed + Survived)) / 10)
                & "."
                & Trim (Natural'Image ((Killed * 1000 / (Killed + Survived)) mod 10))
                & " %");
   end if;
   for S of Survivors loop
      Put_Line ("  survivor: " & S);
   end loop;
end Mutate;
