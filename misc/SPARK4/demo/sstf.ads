package SSTF with SPARK_Mode is
   
   -- Define logical constraints for our disk layout
   Max_Requests : constant := 1000;
   type Track_Index is range 0 .. 100_000;
   
   -- Constrain our arrays to simplify proofs and prevent buffer overflows
   subtype Request_Index is Integer range 1 .. Max_Requests;
   type Track_Array is array (Request_Index range <>) of Track_Index;

   -- Calculates the SSTF schedule
   procedure Get_SSTF_Schedule
     (Initial_Head : in     Track_Index;
      Requests     : in     Track_Array;
      Schedule     :    out Track_Array)
   with
     -- The precondition only asks for matching lengths and at least one
     -- request; Schedule (Schedule'First + K) is the K-th serviced track,
     -- whatever 'First either array has.
     Pre  => Requests'Length >= 1 and then
             Schedule'Length = Requests'Length,
     -- The Depends contract specifies information flow (optional but good practice in SPARK)
     Depends => (Schedule => (Initial_Head, Requests));

end SSTF;
