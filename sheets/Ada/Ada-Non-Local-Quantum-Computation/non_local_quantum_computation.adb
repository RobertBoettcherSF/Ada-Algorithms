package body Non_Local_Quantum_Computation is

   function T_Gate_Bound (Qubits : Qubit_Count; T_Gates : Gate_Count) return Entanglement_Cost is
      Factor : Natural := 1;
      Result : Natural;
   begin
      for I in 1 .. T_Gates loop
         if Factor > Natural'Last / 2 then
            raise Constraint_Error with "T-gate bound overflow";
         end if;
         Factor := Factor * 2;
      end loop;

      if Natural(Qubits) > Natural'Last / Factor then
         raise Constraint_Error with "T-gate bound overflow";
      end if;
      Result := Natural(Qubits) * Factor;
      return Entanglement_Cost(Result);
   end T_Gate_Bound;

   function T_Depth_Bound (Qubits : Qubit_Count; Depth : T_Depth) return Entanglement_Cost is
      Base : constant Natural := 68 * Natural(Qubits);
      Result : Natural := 1;
   begin
      for I in 1 .. Depth loop
         if Result > Natural'Last / Base then
            raise Constraint_Error with "T-depth bound overflow";
         end if;
         Result := Result * Base;
      end loop;
      return Entanglement_Cost(Result);
   end T_Depth_Bound;

   function Port_Teleportation_Cost (Qubits : Qubit_Count; Mode : Exponential_Mode) return Entanglement_Cost is
      N_Val : constant Natural := Natural(Qubits);
      Result : Natural := 1;
   begin
      case Mode is
         when Single_Exponential =>
            for I in 1 .. (2 * N_Val) loop
               if Result > Natural'Last / 2 then
                  raise Constraint_Error with "Single exponential overflow";
               end if;
               Result := Result * 2;
            end loop;
         when Double_Exponential =>
            declare
               Inner : Natural := 1;
            begin
               for I in 1 .. N_Val loop
                  if Inner > Natural'Last / 2 then
                     raise Constraint_Error with "Double exponential inner overflow";
                  end if;
                  Inner := Inner * 2;
               end loop;
               if Inner > Natural'Last / Inner then
                  raise Constraint_Error with "Double exponential overflow";
               end if;
               Inner := Inner * Inner;
               for I in 1 .. Inner loop
                  if Result > Natural'Last / 2 then
                     raise Constraint_Error with "Double exponential outer overflow";
                  end if;
                  Result := Result * 2;
               end loop;
            end;
      end case;
      return Entanglement_Cost(Result);
   end Port_Teleportation_Cost;

   function Routing_Entanglement_Cost (Input_Bits : Natural; CDS_Random_Bits : Natural) return Entanglement_Cost is
   begin
      if Input_Bits = 0 or else CDS_Random_Bits = 0 then
         raise Invalid_Parameters;
      end if;
      pragma Warnings (Off, "condition can only be True*");
      if CDS_Random_Bits > Natural'Last - Input_Bits then
         raise Constraint_Error with "Routing entanglement cost overflow";
      end if;
      pragma Warnings (On, "condition can only be True*");
      return Entanglement_Cost(CDS_Random_Bits + Input_Bits);
   end Routing_Entanglement_Cost;

   function Validate_Circuit (Qubits : Qubit_Count; T_Gates : Gate_Count; Depth : T_Depth) return Boolean is
   begin
      if Qubits = 0 then
         return False;
      end if;
      if T_Gates > 10_000 or Depth > 1_000 then
         return False;
      end if;
      return True;
   end Validate_Circuit;

end Non_Local_Quantum_Computation;
