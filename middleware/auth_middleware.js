/**
 * Ruby Boby Authentication Middleware
 * Ensures that only verified adults can manage personas and account settings.
 */

const verifyParent = (req, res, next) => {
    const { userRole, isVerifiedAdult } = req.user || {};

    if (userRole !== 'parent' || !isVerifiedAdult) {
        return res.status(403).json({
            error: "Access Denied",
            message: "Only verified parents or guardians can access these settings."
        });
    }

    next();
};

const validateChildSession = (req, res, next) => {
    const { sessionId, childId } = req.headers;

    if (!sessionId || !childId) {
        return res.status(401).json({
            error: "Unauthorized",
            message: "Invalid child session. Please have a parent log in first."
        });
    }

    next();
};

module.exports = {
    verifyParent,
    validateChildSession
};
