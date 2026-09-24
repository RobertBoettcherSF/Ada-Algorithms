-- unicode_collation.adb
-- Implementation of the Unicode Collation Algorithm logic
package body Unicode_Collation is

   -----------------------------------------------------
   -- DUCET External Data Mocking
   -----------------------------------------------------
   function Get_Default_Table return Character_Table is
      Table : Character_Table := (others => (Primary => 9999, Secondary => 0, Tertiary => 0));
   begin
      -- Standardize basic Alphabet (Primary weights matter, Case is Tertiary)
      for I in Character'Pos('a') .. Character'Pos('z') loop
         declare
            C : Character := Character'Val(I);
            Upper_C : Character := Character'Val(I - 32);
            Base_Weight : Weight_Level := Weight_Level(I * 10);
         begin
            -- Lowercase: Primary = Base, Secondary = 20, Tertiary = 2 (Lower)
            Table(C) := (Primary => Base_Weight, Secondary => 20, Tertiary => 2);
            -- Uppercase: Primary = Base, Secondary = 20, Tertiary = 8 (Upper)
            Table(Upper_C) := (Primary => Base_Weight, Secondary => 20, Tertiary => 8);
         end;
      end loop;

      -- Numbers (sorted before letters usually)
      for I in Character'Pos('0') .. Character'Pos('9') loop
         Table(Character'Val(I)) := (Primary => Weight_Level(I), Secondary => 20, Tertiary => 2);
      end loop;

      -- Punctuation (Ignorable at primary level in UCA standard)
      Table(' ') := (Primary => 0, Secondary => 0, Tertiary => 1);
      Table('-') := (Primary => 0, Secondary => 0, Tertiary => 2);
      Table(',') := (Primary => 0, Secondary => 0, Tertiary => 3);

      return Table;
   end Get_Default_Table;

   -----------------------------------------------------
   -- Core Algorithm Helpers
   -----------------------------------------------------
   function Get_Weights (Str : String; Table : Character_Table) return Weight_Array is
      Result : Weight_Array(1 .. Str'Length);
   begin
      for I in Str'Range loop
         Result(1 + I - Str'First) := Table(Str(I));
      end loop;
      return Result;
   end Get_Weights;

   function Extract_Level_Weights (Weights : Weight_Array; Level : Integer) return Level_Array is
      Temp : Level_Array(1 .. Weights'Length);
      Count : Natural := 0;
   begin
      for I in Weights'Range loop
         declare
            Val : Weight_Level;
         begin
            case Level is
               when 1 => Val := Weights(I).Primary;
               when 2 => Val := Weights(I).Secondary;
               when 3 => Val := Weights(I).Tertiary;
               when others => Val := 0;
            end case;

            -- In UCA, 0-weights are skipped for comparison at that level
            if Val /= 0 then
               Count := Count + 1;
               Temp(Count) := Val;
            end if;
         end;
      end loop;
      return Temp(1 .. Count);
   end Extract_Level_Weights;

   -----------------------------------------------------
   -- Multi-Level Comparison Engine
   -----------------------------------------------------
   function Compare_Weights (Left, Right : Weight_Array) return Collation_Result is
   begin
      -- Process Levels 1 to 3 sequentially
      for Lvl in 1 .. 3 loop
         declare
            L_Level : constant Level_Array := Extract_Level_Weights(Left, Lvl);
            R_Level : constant Level_Array := Extract_Level_Weights(Right, Lvl);
            Min_Len : constant Natural := Natural'Min(L_Level'Length, R_Level'Length);
         begin
            for I in 1 .. Min_Len loop
               if L_Level(I) < R_Level(I) then return Less; end if;
               if L_Level(I) > R_Level(I) then return Greater; end if;
            end loop;

            -- If common prefix is identical, the shorter one is "Less"
            if L_Level'Length < R_Level'Length then return Less; end if;
            if L_Level'Length > R_Level'Length then return Greater; end if;
         end;
      end loop;

      return Equal;
   end Compare_Weights;

   -----------------------------------------------------
   -- Public Variants
   -----------------------------------------------------
   function Compare_Standard (Left, Right : String; Table : Character_Table) return Collation_Result is
   begin
      if Left'Length = 0 and Right'Length = 0 then return Equal; end if;
      if Left'Length = 0 then return Less; end if;
      if Right'Length = 0 then return Greater; end if;

      return Compare_Weights(Get_Weights(Left, Table), Get_Weights(Right, Table));
   end Compare_Standard;

   function Compare_Ignore_Punctuation (Left, Right : String; Table : Character_Table) return Collation_Result is
      Mod_Table : Character_Table := Table;
   begin
      -- Variable weighting: shift punctuation weights to absolute zero (completely ignored)
      Mod_Table(' ') := (0, 0, 0);
      Mod_Table('-') := (0, 0, 0);
      Mod_Table(',') := (0, 0, 0);
      return Compare_Standard(Left, Right, Mod_Table);
   end Compare_Ignore_Punctuation;

   function Apply_Tailoring (Base_Table : Character_Table; 
                             Target     : Character; 
                             New_Weight : Collation_Weight) return Character_Table is
      Mod_Table : Character_Table := Base_Table;
   begin
      Mod_Table(Target) := New_Weight;
      return Mod_Table;
   end Apply_Tailoring;

end Unicode_Collation;
