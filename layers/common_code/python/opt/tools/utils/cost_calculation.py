import math


class CostCalculator:
    @staticmethod
    def calculate_personal_cost(au: float, days: int, passengers: int) -> float:
        """
        Calculate the cost for a personal vehicle based on distance (AU), parking days, and number of passengers.
        Each vehicle can fit up to 4 passengers.

        Args:
            au (float): Distance in Astronomical Units.
            days (int): Number of days for parking the ship.
            passengers (int): Number of passengers.

        Returns:
            float: Total cost for the personal vehicle.
        """
        number_of_vehicles = math.ceil(passengers / 4)
        return ((0.3 * au) + (5 * days)) * number_of_vehicles

    @staticmethod
    def calculate_hstc_cost(au: float, passengers: int) -> float:
        """
        Calculate the cost for an HSTC vehicle based on distance (AU) and number of passengers.
        Each vehicle can fit up to 5 passengers.
        Args:
            au (float): Distance in Astronomical Units.
            passengers (int): Number of passengers.

        Returns:
            float: Total cost for the HSTC vehicle.
        """
        number_of_vehicles = math.ceil(passengers / 5)
        return (0.45 * au) * number_of_vehicles
