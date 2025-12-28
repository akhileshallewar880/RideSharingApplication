using System;
using AutoMapper;
using RideSharing.API.Models.Domain;
using RideSharing.API.Models.DTO;

namespace RideSharing.API.AutoMappings;

public class AutoMappingProfiles : Profile
{
    public AutoMappingProfiles()
    {
        // Legacy mappings
        CreateMap<Models.Domain.Route, RouteDto>();
        CreateMap<CreateRouteRequest, Models.Domain.Route>();
        CreateMap<ScheduleTemplate, ScheduleTemplateDto>();
        CreateMap<CreateScheduleTemplateRequest, ScheduleTemplate>();

        // User & Profile mappings - simplified to existing properties only
        CreateMap<UserProfile, UserProfileDetailDto>();
        CreateMap<UpdateUserProfileDto, UserProfile>()
            .ForAllMembers(opts => opts.Condition((src, dest, srcMember) => srcMember != null));

        // Ride mappings
        CreateMap<Ride, AvailableRideDto>()
            .ForMember(dest => dest.RideId, opt => opt.MapFrom(src => src.Id))
            .ForMember(dest => dest.DriverName, opt => opt.MapFrom(src => src.Driver.User.Profile != null ? src.Driver.User.Profile.Name : ""))
            .ForMember(dest => dest.DriverRating, opt => opt.MapFrom(src => src.Driver.User.Profile != null ? src.Driver.User.Profile.Rating : 0))
            .ForMember(dest => dest.VehicleType, opt => opt.MapFrom(src => src.Vehicle.VehicleType))
            .ForMember(dest => dest.VehicleModel, opt => opt.MapFrom(src => src.Vehicle.Make + " " + src.Vehicle.Model))
            .ForMember(dest => dest.VehicleNumber, opt => opt.MapFrom(src => src.Vehicle.RegistrationNumber))
            .ForMember(dest => dest.AvailableSeats, opt => opt.MapFrom(src => src.TotalSeats - src.BookedSeats))
            .ForMember(dest => dest.DepartureTime, opt => opt.MapFrom(src => src.DepartureTime.ToString("yyyy-MM-dd HH:mm")))
            .ForMember(dest => dest.EstimatedDuration, opt => opt.MapFrom(src => "N/A"));

        // Booking mappings
        CreateMap<Booking, BookingResponseDto>()
            .ForMember(dest => dest.DriverDetails, opt => opt.MapFrom(src => src.Ride.Driver));

        CreateMap<Driver, DriverDetailsDto>()
            .ForMember(dest => dest.Name, opt => opt.MapFrom(src => src.User.Profile != null ? src.User.Profile.Name : ""))
            .ForMember(dest => dest.PhoneNumber, opt => opt.MapFrom(src => src.User.PhoneNumber))
            .ForMember(dest => dest.Rating, opt => opt.MapFrom(src => src.User.Profile != null ? src.User.Profile.Rating : 0))
            .ForMember(dest => dest.VehicleModel, opt => opt.MapFrom(src => ""))
            .ForMember(dest => dest.VehicleNumber, opt => opt.MapFrom(src => ""));

        CreateMap<Booking, RideHistoryItemDto>()
            .ForMember(dest => dest.TimeSlot, opt => opt.MapFrom(src => src.Ride.DepartureTime.ToString("HH:mm")))
            .ForMember(dest => dest.VehicleType, opt => opt.MapFrom(src => src.Ride.Vehicle.VehicleType));

        // Vehicle mappings
        CreateMap<Vehicle, VehicleDto>()
            .ForMember(dest => dest.VehicleId, opt => opt.MapFrom(src => src.Id));

        // Driver mappings
        CreateMap<Ride, DriverRideDto>()
            .ForMember(dest => dest.RideId, opt => opt.MapFrom(src => src.Id));
    }
}

