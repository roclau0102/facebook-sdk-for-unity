namespace Facebook.Unity.Tests
{
    using System;
    using UnityEngine;
    using NUnit.Framework;
    using Facebook.Unity;

    public abstract class SharePhoto : FacebookTestClass
    {
        [Test]
        public void SharePhotoWithTexture2D()
        {
            IShareResult result = null;

            FB.SharePhoto(
                Texture2D.blackTexture,
                callback:(r) => {
                    result = r;
                };

            Assert.IsNotNull(result);
            FacebookLogger.Log(result.RawResult);
        }
    }
}