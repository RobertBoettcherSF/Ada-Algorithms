--  Version: 0.001
--  Modular_Arithmetic.Big_Ring: Z/NZ for the largest prime below 2**63,
--  N = 2**63 - 25.  A library-level instance so that GNATprove proves the
--  generic Ring for a modulus at the top of the range (REQ-023).

pragma Ada_2022;

with Modular_Arithmetic.Ring;

package Modular_Arithmetic.Big_Ring is
  new Modular_Arithmetic.Ring (Modulus => 2**63 - 25);
