using Xunit;

namespace DailyDietAPI.IntegrationTest
{
    [CollectionDefinition(MainTestColection.Name)]
    public class MainTestColection: ICollectionFixture<HttpHostFixture>
    {
        public const string Name = "Main test collection";
    }
}
