pragma Ada_2022;

package body Count_And_Say_Stub with SPARK_Mode => On is
   procedure Describe (Number : Positive; Text : out Text_Buffer;
                       Last : out Natural; Ok : out Boolean)
   is
      Next     : Text_Buffer := [others => '0'];
      New_Last : Natural;
      I        : Positive;
      Run      : Positive;
   begin
      Text := [others => '0'];
      Text (1) := '1';
      Last := 1;
      Ok := True;
      for Step in 2 .. Number loop
         pragma Loop_Invariant (Ok and then Last in 1 .. Max_Text);
         pragma Loop_Invariant (for all K in 1 .. Last => Text (K) in '1' .. '9');
         New_Last := 0;
         I := 1;
         while I <= Last loop
            pragma Loop_Invariant (I <= Last);
            pragma Loop_Invariant (New_Last <= 2 * (I - 1));
            pragma Loop_Invariant (New_Last mod 2 = 0);
            pragma Loop_Invariant
              (for all K in 1 .. New_Last => Next (K) in '1' .. '9');
            Run := 1;
            while I + Run <= Last and then Text (I + Run) = Text (I) loop
               pragma Loop_Invariant (Run <= Last - I);
               Run := Run + 1;
            end loop;
            --  A run longer than 9 cannot be written as one digit (it never
            --  happens in this sequence, but it is not proved here).
            if Run > 9 or else New_Last + 2 > Max_Text then
               Last := 0;
               Ok := False;
               return;
            end if;
            Next (New_Last + 1) := Character'Val (Character'Pos ('0') + Run);
            Next (New_Last + 2) := Text (I);
            New_Last := New_Last + 2;
            I := I + Run;
         end loop;
         Text := Next;
         Last := New_Last;
      end loop;
   end Describe;
end Count_And_Say_Stub;
